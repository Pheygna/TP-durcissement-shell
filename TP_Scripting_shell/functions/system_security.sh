#!/bin/bash

# Fonction pour activer les mises à jour automatiques de sécurité
function enable_auto_updates() {
    echo "Activation des mises à jour automatiques de sécurité..."

    if ! dpkg -l | grep unattended-upgrades > /dev/null; then
        apt-get install unattended-upgrades -y
    fi

    sudo dpkg-reconfigure --priority=low unattended-upgrades
    echo "Mises à jour automatiques activées."
    logger "Mises à jour automatiques activées"
}

# Fonction pour activer la 2FA pour SSH
function enable_2fa_for_ssh() {
    echo "Installation et configuration de l'authentification à deux facteurs pour SSH..."

    # Installer libpam-google-authenticator si ce n'est pas déjà fait
    if ! dpkg -l | grep libpam-google-authenticator > /dev/null; then
        apt-get update
        apt-get install -y libpam-google-authenticator
    fi

    # Configurer PAM pour utiliser Google Authenticator
    echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd

    # Configurer SSH pour utiliser la 2FA
    sed -i 's/^#ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^UsePAM no/UsePAM yes/' /etc/ssh/sshd_config

    # Redémarrer le service SSH pour appliquer les modifications
    systemctl restart sshd

    echo "Authentification à deux facteurs activée pour SSH. Chaque utilisateur devra configurer Google Authenticator avec 'google-authenticator'."
    logger "Authentification à deux facteurs activée pour SSH"
	
	# Générer le code QR pour l'utilisateur courant
    echo "Configuration du 2FA pour l'utilisateur courant..."
    google-authenticator -t -d -f -r 3 -R 30 -w 3
} 	

# Fonction pour désactiver les services inutiles
function disable_unnecessary_services() {
    echo "Désactivation des services inutiles..."

    systemctl disable cups.service || echo "CUPS non trouvé ou déjà désactivé"
    systemctl stop cups.service || echo "CUPS déjà arrêté"
    
    echo "Services inutiles désactivés."
    logger "Services inutiles désactivés"
}

# Fonction pour sécuriser les permissions des fichiers critiques
function secure_file_permissions() {
    echo "Sécurisation des permissions des fichiers critiques..."

    chmod 600 /etc/ssh/sshd_config
    chmod 600 /etc/passwd
    chmod 600 /etc/shadow
    chmod 700 /root

    echo "Permissions sécurisées."
    logger "Permissions des fichiers critiques sécurisées"
}
