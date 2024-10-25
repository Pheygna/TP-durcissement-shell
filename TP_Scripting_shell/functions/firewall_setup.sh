#!/bin/bash

# Fonction pour configurer le pare-feu UFW
function setup_firewall() {
    echo "Configuration du pare-feu UFW..."

    # Vérifier si UFW est installé
    if ! command -v ufw &> /dev/null; then
        echo "UFW n'est pas installé. Installation en cours..."
        apt-get install ufw -y
    fi

    # Configuration par défaut de UFW
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Autoriser uniquement les services sécurisés
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https

    # Activer UFW
    sudo ufw enable
    echo "Pare-feu UFW activé."

    logger "Pare-feu UFW activé : SSH, HTTP, HTTPS autorisés"
}
