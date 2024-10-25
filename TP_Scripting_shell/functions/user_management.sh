#!/bin/bash

# Fonction pour gérer les utilisateurs
function manage_users() {
    echo "Gestion des utilisateurs..."

    read -p "Entrez le nom de l'utilisateur à créer : " USERNAME

    # Vérifier si l'utilisateur existe déjà
    if id "$USERNAME" >/dev/null 2>&1; then
        echo "L'utilisateur $USERNAME existe déjà."
    else
        # Ajouter l'utilisateur
        sudo adduser "$USERNAME"
        sudo usermod -aG sudo "$USERNAME"
        echo "L'utilisateur $USERNAME a été créé et ajouté au groupe sudo."

        # Ajouter un message au journal
        logger "Utilisateur $USERNAME créé et ajouté au groupe sudo"
    fi
}
