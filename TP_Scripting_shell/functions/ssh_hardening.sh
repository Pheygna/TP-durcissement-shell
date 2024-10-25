#!/bin/bash

# Variables à modifier selon votre configuration
SSH_USER="root"            # Nom de l'utilisateur SSH, par exemple "root" ou un autre utilisateur
SSH_PORT="22"              # Port SSH
LOCAL_PUB_KEY="/root/.ssh/id_rsa.pub"  # Chemin de la clé publique locale
AUTHORIZED_KEYS="/root/.ssh/authorized_keys"  # Chemin vers authorized_keys sur le serveur

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

# Fonction pour générer une clé SSH si elle n'existe pas
function generate_ssh_key() {
    if [ ! -f "$LOCAL_PUB_KEY" ]; then
        echo "Clé publique non trouvée. Génération d'une nouvelle paire de clés SSH..."
        ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -q -N ""
        echo "Clé SSH générée avec succès."
    else
        echo "Clé publique existante trouvée à $LOCAL_PUB_KEY"
    fi
}

# Fonction pour ajouter la clé publique à authorized_keys
function add_public_key() {
    echo "Ajout de la clé publique à authorized_keys..."

    # Vérification si le fichier authorized_keys existe, sinon le créer
    if [ ! -d "/root/.ssh" ]; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
    fi

    # Ajouter la clé publique si elle n'est pas déjà présente
    if [ -f "$LOCAL_PUB_KEY" ]; then
        if ! grep -q "$(cat $LOCAL_PUB_KEY)" "$AUTHORIZED_KEYS"; then
            cat "$LOCAL_PUB_KEY" >> "$AUTHORIZED_KEYS"
            chmod 600 "$AUTHORIZED_KEYS"
            echo "Clé publique ajoutée à $AUTHORIZED_KEYS"
        else
            echo "La clé publique est déjà présente dans $AUTHORIZED_KEYS."
        fi
    else
        echo "Erreur : La clé publique locale n'existe toujours pas à $LOCAL_PUB_KEY."
        exit 1
    fi
}

# Appel des fonctions
secure_ssh
generate_ssh_key
add_public_key
