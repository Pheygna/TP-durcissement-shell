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
