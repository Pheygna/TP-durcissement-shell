#!/bin/bash

# Activer les options pour la gestion des erreurs et de sécurité
set -e  # Arrêter le script en cas d'erreur
set -u  # Considérer les variables non définies comme des erreurs
set -o pipefail  # Gérer correctement les erreurs dans les pipes

# Vérification d'exécution en tant qu'utilisateur normal, sauf si nécessaire
#"if [ "$EUID" -eq 0 ]; then
#    echo "Erreur : Ne pas exécuter ce script en tant que root."
#    exit 1
#fi

# Vérification de l'intégrité d'un fichier avec SHA256
#function verify_integrity() {
#    local file=$1
#    local expected_hash=$2
#    local file_hash=$(sha256sum "$file" | awk '{ print $1 }')
#
#    if [ "$expected_hash" != "$file_hash" ]; then
#        echo "Erreur : L'intégrité du fichier $file est compromise."
#        exit 1
#    else
#        echo "L'intégrité de $file est vérifiée."
#    fi
#}

# Fonction pour appliquer les permissions d'exécution uniquement si nécessaire
function apply_permissions() {
    echo "Application des permissions d'exécution aux scripts..."

    local files=("main_script.sh" "functions/ssh_hardening.sh" "functions/firewall_setup.sh" \
                 "functions/user_management.sh" "functions/log_management.sh" "functions/system_security.sh" \
                 "config/config_file.sh")

    for file in "${files[@]}"; do
        if [ ! -x "$file" ]; then
            chmod +x "$file"
            echo "Permissions exécutables appliquées à $file"
        else
            echo "Permissions déjà présentes pour $file"
        fi
    done
}

# Vérifier l'intégrité avant d'appliquer les permissions
# Ajoutez les bons hash SHA256 pour chaque fichier
#verify_integrity "main_script.sh" "EXPECTED_SHA256_HASH_MAIN_SCRIPT"
#verify_integrity "functions/ssh_hardening.sh" "EXPECTED_SHA256_HASH_SSH_HARDENING"
#verify_integrity "functions/firewall_setup.sh" "EXPECTED_SHA256_HASH_FIREWALL_SETUP"
#verify_integrity "functions/user_management.sh" "EXPECTED_SHA256_HASH_USER_MANAGEMENT"
#verify_integrity "functions/log_management.sh" "EXPECTED_SHA256_HASH_LOG_MANAGEMENT"
#verify_integrity "functions/system_security.sh" "EXPECTED_SHA256_HASH_SYSTEM_SECURITY"
#verify_integrity "config/config_file.sh" "EXPECTED_SHA256_HASH_CONFIG_FILE"

# Appliquer les permissions après vérification de l'intégrité
apply_permissions

# Sourçage des fichiers
source ./functions/ssh_hardening.sh || { echo "Erreur : Impossible de sourcer ssh_hardening.sh"; exit 1; }
source ./functions/firewall_setup.sh || { echo "Erreur : Impossible de sourcer firewall_setup.sh"; exit 1; }
source ./functions/user_management.sh || { echo "Erreur : Impossible de sourcer user_management.sh"; exit 1; }
source ./functions/log_management.sh || { echo "Erreur : Impossible de sourcer log_management.sh"; exit 1; }
source ./functions/system_security.sh || { echo "Erreur : Impossible de sourcer system_security.sh"; exit 1; }
source ./config/config_file.sh || { echo "Erreur : Impossible de charger le fichier de configuration"; exit 1; }

# Fonction pour vérifier et installer SSH si nécessaire
function install_ssh() {
    # Vérifier si SSH est installé
    if ! dpkg -l | grep -q openssh-server; then
        echo "Le serveur SSH n'est pas installé. Installation en cours..."
        sudo apt-get update
        sudo apt-get install -y openssh-server

        # Vérification si l'installation s'est bien déroulée
        if [ $? -ne 0 ]; then
            echo "Erreur lors de l'installation de openssh-server."
            exit 1
        fi

        echo "Le serveur SSH a été installé avec succès."
    else
        echo "Le serveur SSH est déjà installé."
    fi
}

# Fonction pour sécuriser SSH
function secure_ssh() {
    echo "Sécurisation de SSH..."

    # Vérifier si le fichier sshd_config existe
    if [ ! -f /etc/ssh/sshd_config ]; then
        echo "Erreur : Le fichier /etc/ssh/sshd_config n'existe pas. Vérification de l'installation SSH..."
        install_ssh  # Si le fichier n'existe pas, tenter d'installer SSH à nouveau
    fi
    
    # Vérifier encore après l'installation
    if [ ! -f /etc/ssh/sshd_config ]; then
        echo "Erreur : Le fichier /etc/ssh/sshd_config n'a pas été généré après l'installation. Abandon."
        exit 1
    fi

    # Sauvegarder le fichier sshd_config avant de le modifier
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    echo "Sauvegarde de /etc/ssh/sshd_config effectuée."

    # Désactiver l'authentification par mot de passe et désactiver l'accès root
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

    # Redémarrer le service SSH pour appliquer les changements
    sudo systemctl restart sshd
    echo "SSH sécurisé et service redémarré."
}

# Fonction principale qui appelle les différentes fonctions de durcissement
main(){
  echo "Démarrage du processus d'automatisation et de durcissement..."

  secure_ssh
  add_public_key
  setup_firewall
  manage_users
  install_rsyslog
  configure_log_file
  monitor_logs
  enable_auto_updates
  disable_unnecessary_services
  secure_file_permissions

  echo "Processus terminé avec succès."
}

# Appel de la fonction principale
main
