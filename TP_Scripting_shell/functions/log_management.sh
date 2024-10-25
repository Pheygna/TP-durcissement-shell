# functions/log_management.sh

# Fonction pour vérifier et installer rsyslog si nécessaire
function install_rsyslog() {
    # Vérifier si rsyslog est installé
    if ! dpkg -l | grep -q rsyslog; then
        echo "rsyslog n'est pas installé. Installation en cours..."
        sudo apt-get update
        sudo apt-get install -y rsyslog

        if [ $? -ne 0 ]; then
            echo "Erreur lors de l'installation de rsyslog."
            exit 1
        fi
        echo "rsyslog a été installé avec succès."
    else
        echo "rsyslog est déjà installé."
    fi

    # Redémarrer rsyslog
    sudo systemctl restart rsyslog
    echo "Le service rsyslog a été redémarré."
}

# Fonction pour vérifier et configurer le fichier de log /var/log/auth.log
function configure_log_file() {
    local log_file="/var/log/auth.log"
    
    if [ ! -f "$log_file" ]; then
        echo "Le fichier de log $log_file n'existe pas. Création du fichier..."
        sudo touch "$log_file"
        sudo chmod 640 "$log_file"
        sudo chown root:adm "$log_file"
        echo "Fichier de log $log_file créé avec succès."
    else
        echo "Le fichier de log $log_file existe déjà."
    fi
}

# Fonction pour surveiller les logs d'authentification
function monitor_logs() {
    local log_file="/var/log/auth.log"
    
    echo "Configuration de la surveillance des logs..."

    if [ -f "$log_file" ]; then
        tail -f "$log_file" &
        echo "Surveillance des logs activée."
        logger "Surveillance des logs activée sur $log_file"
    else
        echo "Erreur : Le fichier de log $log_file n'existe pas après vérification."
        exit 1
    fi
}
