#!/bin/bash

# Variables à modifier selon votre configuration
SSH_USER="root"            # Nom de l'utilisateur SSH, par exemple "root" ou un autre utilisateur
SSH_PORT="22"              # Port SSH
LOCAL_PUB_KEY="/root/.ssh/id_rsa.pub"  # Chemin de la clé publique locale
AUTHORIZED_KEYS="/root/.ssh/authorized_keys"  # Chemin vers authorized_keys sur le serveur

# Fonction pour configurer SSH
function secure_ssh() {
    echo "Sécurisation de SSH..."

    SSH_CONFIG="/etc/ssh/sshd_config"

    # Vérification si le fichier de configuration SSH existe
    if [ -f "$SSH_CONFIG" ]; then
        # Sauvegarde du fichier de configuration
        cp "$SSH_CONFIG" "$SSH_CONFIG.bak"
        echo "Sauvegarde de $SSH_CONFIG effectuée."

        # Modifier les configurations SSH
        sed -i 's/^#PermitRootLogin yes/PermitRootLogin prohibit-password/' $SSH_CONFIG
        sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG
        sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' $SSH_CONFIG

        # Redémarrer le service SSH pour appliquer les modifications
        systemctl restart sshd && echo "SSH sécurisé et service redémarré."
    else
        echo "Erreur : Le fichier $SSH_CONFIG n'existe pas."
        exit 1
    fi
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
