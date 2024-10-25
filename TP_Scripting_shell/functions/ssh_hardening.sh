#!/bin/bash

# Variables à modifier selon votre configuration
SSH_USER="user"            # Nom de l'utilisateur SSH
SSH_PORT="22"              # Port SSH
AUTHORIZED_KEYS="/home/$SSH_USER/.ssh/authorized_keys"  # Chemin vers authorized_keys sur le serveur

# Clé publique SSH en dur
HARDCODED_SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdB6idmQkCnWPIzOFTLcWzR/0i1Glq1YKrIsx79oMSAUGLJpFukwNG5e1aQ+XTUd1uInznPeNJ5qn2pVpN2ebSfwW9kA3xHx6EtfSDw8/BZ//sFqaXlroWYyrr/ErsIfBBDhL0VIr2c+ZspfhwNssYtKCf6C4UKJDMqhDuv8ILHJSBuQpkeOna8nwhMzOg9UsH8lBIaF4vuYgI8zDlEGGbA14hgGyTIwvcibKwq8XGNF0fuyb4InOLkk7ZEJj9mC6Xj37548f4CPHUk78lCyVDlg/4NQymiSyqgLYpMU7xUC5njljLsE7HWLG7fv8UpxY9E73EvWaXRKfFWRktFZGx cgabr@xlPryZeeQG"

# Vérifier si le script est exécuté avec les privilèges root
if [ "$(id -u)" != "0" ]; then
    echo "Ce script doit être exécuté en tant que root." 1>&2
    exit 1
fi

# Fonction pour installer SSH si nécessaire
function install_ssh() {
    if ! dpkg -l | grep -q openssh-server; then
        echo "Le serveur SSH n'est pas installé. Installation en cours..."
        sudo apt-get update
        sudo apt-get install -y openssh-server
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
        echo "Erreur : Le fichier /etc/ssh/sshd_config n'existe pas. Installation de SSH..."
        install_ssh
    fi
    
    # Sauvegarder le fichier sshd_config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    echo "Sauvegarde de /etc/ssh/sshd_config effectuée."

    # Désactiver l'authentification par mot de passe et désactiver l'accès root
    sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

    # Configurer le port SSH si besoin
    sudo sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

    # Redémarrer le service SSH
    echo "Redémarrage du service SSH..."
    sudo systemctl restart sshd
    if [ $? -eq 0 ]; then
        echo "Service SSH redémarré avec succès."
    else
        echo "Erreur lors du redémarrage de SSH."
    fi
}

# Fonction pour ajouter la clé publique en dur à authorized_keys
function add_public_key() {
    echo "Ajout de la clé publique à authorized_keys..."

    # Vérification si le fichier authorized_keys existe, sinon le créer
    if [ ! -d "/home/$SSH_USER/.ssh" ]; then
        mkdir -p /home/$SSH_USER/.ssh
        chmod 700 /home/$SSH_USER/.ssh
    fi

    # Ajouter la clé publique si elle n'est pas déjà présente
    if ! grep -q "$HARDCODED_SSH_KEY" "$AUTHORIZED_KEYS"; then
        echo "$HARDCODED_SSH_KEY" >> "$AUTHORIZED_KEYS"
        chmod 600 "$AUTHORIZED_KEYS"
        chown $SSH_USER:$SSH_USER "$AUTHORIZED_KEYS"
        echo "Clé publique ajoutée à $AUTHORIZED_KEYS"
    else
        echo "La clé publique est déjà présente dans $AUTHORIZED_KEYS."
    fi
}

# Appel des fonctions
secure_ssh
add_public_key
