#!/bin/bash

set -e  # Exit on any error

# Load configuration
CONFIG_FILE="config/config.cfg"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file $CONFIG_FILE not found! Exiting."
    exit 1
fi

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Functions for deploying services
deploy_all() {
    log "Install prerequisites and depedencies of Socarium..."
    sudo ./install_prerequisites.sh
    log "Calling install_all.sh to deploy all core services..."
    sudo ./install_all.sh || { log "Failed to execute install_all.sh. Exiting."; exit 1; }
    log "All core services deployed successfully via install_all.sh."
    cd $BASE_DIR
}

deploy_wazuh() {
    log "Deploying Wazuh..."
    cd "$BASE_DIR/modules/wazuh"
    sudo chmod +x wazuh.sh
    sudo ./wazuh.sh
    log "Wazuh deployed successfully."
    cd $BASE_DIR
}

deploy_iris() {
    log "Deploying DFIR IRIS..."
    cd "$BASE_DIR/modules/iris-web"
    sudo chmod +x dfir-iris.sh
    sudo ./dfir-iris.sh
    log "DFIR IRIS deployed successfully."
    cd $BASE_DIR
}

deploy_shuffle() {
    log "Deploying Shuffle..."
    cd "$BASE_DIR/modules/shuffle"
    sudo chmod +x shuffle.sh
    sudo ./shuffle.sh
    log "Shuffle deployed successfully."
    cd $BASE_DIR
}

deploy_misp() {
    log "Deploying MISP..."
    cd "$BASE_DIR/modules/misp"
    sudo chmod +x misp.sh
    sudo ./misp.sh
    log "MISP deployed successfully."
    cd $BASE_DIR
}

deploy_grafana() {
    log "Deploying Grafana and Prometheus..."
    cd "$BASE_DIR/modules/grafana"
    sudo docker-compose up -d || { log "Failed to deploy Grafana and Prometheus."; }
    log "Grafana and Prometheus deployed successfully."
    cd $BASE_DIR
}

deploy_yara() {
    log "Deploying Yara..."
    cd "$BASE_DIR/modules/yara"
    # Add Yara-specific deployment steps here
    sudo apt install yara -y
    log "Yara deployed successfully."
    cd $BASE_DIR
}

deploy_opencti() {
    log "Deploying OpenCTI..."
    cd "$BASE_DIR/modules/opencti"
    # Add OpenCTI-specific deployment steps here
    sudo chmod +x deploy_opencti.sh
    sudo ./deploy_opencti.sh
    log "OpenCTI deployed successfully."
    cd $BASE_DIR
}

deploy_velociraptor() {
    log "Deploying Velociraptor..."
    cd "$BASE_DIR/modules/velociraptor"
    # Add Velociraptor-specific deployment steps here
    sudo docker-compose up -d
    log "Velociraptor deployed"
    cd $BASE_DIR
    log "Setup API file Integration DFIR IRIS"
    sleep 10  # Check system 10 seconds
    cd $BASE_DIR/modules/velociraptor/velociraptor
    sudo ./velociraptor --config server.config.yaml config api_client --name admin --role administrator api.config.yaml
    sudo cp api.config.yaml $BASE_DIR/iris-web/docker/api.config.yaml
    log "Restart DFIR IRIS..."
    cd $BASE_DIR/iris-web
    sudo docker-compose down
    sudo docker-compose up -d
    log "Velociraptor deployed successfully."
    cd $BASE_DIR
}

integration_wazuh_iris() {
        log "Integration Wazuh - DFIR IRIS..."
        sudo cp $BASE_DIR/modules/wazuh/custom-iris.py /var/lib/docker/volumes/single-node_wazuh_integrations/_data/custom-iris.py
        sudo docker exec -ti single-node-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/custom-iris.py
        sudo docker exec -ti single-node-wazuh.manager-1 chmod 750 /var/ossec/integrations/custom-iris.py
        cd $BASE_DIR
        sudo docker-compose -f $BASE_DIR/wazuh-docker/single-node/docker-compose.yml down
        sudo docker-compose -f $BASE_DIR/wazuh-docker/single-node/docker-compose.yml up -d
        log "Integration Wazuh-DFIR IRIS successfully."
}

integration_wazuh_misp() {
        log "Integration Wazuh - MISP..."
        sudo cp $BASE_DIR/modules/wazuh/custom-misp.py /var/lib/docker/volumes/single-node_wazuh_integrations/_data/custom-misp.py
        sudo docker exec -ti single-node-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/custom-misp.py
        sudo docker exec -ti single-node-wazuh.manager-1 chmod 750 /var/ossec/integrations/custom-misp.py
        sudo cp $BASE_DIR/modules/wazuh/local_rules.xml /var/lib/docker/volumes/single-node_wazuh_etc/_data/rules/local_rules.xml
        sudo docker exec -ti single-node-wazuh.manager-1 chown wazuh:wazuh /var/ossec/etc/rules/local_rules.xml
        sudo docker exec -ti single-node-wazuh.manager-1 chmod 550 /var/ossec/etc/rules/local_rules.xml
        cd $BASE_DIR
        sudo docker-compose -f $BASE_DIR/wazuh-docker/single-node/docker-compose.yml down
        sudo docker-compose -f $BASE_DIR/wazuh-docker/single-node/docker-compose.yml up -d
        log "Integration Wazuh-MISP successfully."
}

integration_wazuh_shuffle() {
        log "Integration Wazuh - Shuffle..."
        sudo cp $BASE_DIR/modules/wazuh/shuffle.py /var/lib/docker/volumes/single-node_wazuh_integrations/_data/shuffle.py
        sudo docker exec -ti single-node-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/shuffle.py
        sudo docker exec -ti single-node-wazuh.manager-1 chmod 750 /var/ossec/integrations/shuffle.py
        cd $BASE_DIR
        sudo docker-compose -f $BASE_DIR/wazuh-docker/single-node/docker-compose.yml down
        sudo docker-compose -f $BASE_DIR/wazuh-docker/single-node/docker-compose.yml up -d
        log "Integration Wazuh - Shuffle successfully."
}

iris_module_wazuhindexer() {
        log "Deploy DFIR IRIS Module Wazuh Indexer"
        cd $BASE_DIR/modules/iris-wazuhindexer-module
        chmod +x buildnpush2iris.sh
        ./buildnpush2iris.sh
        log "Deploy DFIR IRIS Module Wazuh Indexer successfully."
        cd $BASE_DIR
}

iris_module_veloquarantine() {
        log "Deploy DFIR IRIS Module Velociraptor Quarantine"
        cd $BASE_DIR/modules/iris-veloquarantine-module
        chmod +x buildnpush2iris.sh
        ./buildnpush2iris.sh
        log "Deploy DFIR IRIS Module Velociraptor Quarantine successfully."
        cd $BASE_DIR
}

iris_module_veloquarantineremove() {
        log "Deploy DFIR IRIS Module Velociraptor Remove Quarantine"
        cd $BASE_DIR/modules/iris-veloquarantineremove-module
        chmod +x buildnpush2iris.sh
        ./buildnpush2iris.sh
        log "Deploy DFIR IRIS Module Velociraptor Remove Quarantine successfully."
        cd $BASE_DIR
}

iris_module_veloartifact() {
        log "Deploy DFIR IRIS Module Velociraptor Artifact"
        cd $BASE_DIR/modules/iris-velociraptorartifact-module
        chmod +x buildnpush2iris.sh
        ./buildnpush2iris.sh
        log "Deploy DFIR IRIS Module Velociraptor Artifact successfully."
        cd $BASE_DIR
}

tools_config() {
    while true; do
        SECONDARY_CHOICE=$(whiptail --title "Configuration Menu" --menu "Choose a configuration option:" 20 78 12 \
            "1" "Integration Wazuh - DFIR IRIS" \
            "2" "Integration Wazuh - MISP" \
            "3" "Integration Wazuh - Shuffle"\
            "4" "DFIR IRIS Module Wazuh Indexer" \
            "5" "DFIR IRIS Module Velociraptor Quarantine"\
            "6" "DFIR IRIS Module Velociraptor Remove Quarantine"\
            "7" "DFIR IRIS Module Velociraptor Artifact"\
            "8" "Return to Main Menu" 3>&1 1>&2 2>&3)

        case $SECONDARY_CHOICE in
            1) integration_wazuh_iris ;;
            2) integration_wazuh_misp ;;
            3) integration_wazuh_shuffle ;;
            4) iris_module_wazuhindexer ;;
            5) iris_module_veloquarantine ;;
            6) iris_module_veloquarantineremove ;;
            7) iris_module_veloartifact ;;
            8) log "Returning to Main Menu."; break ;; # Exit secondary menu
            *) log "Invalid option. Please try again." ;;
        esac
    done
}

socarium_manual_config() {
while true; do
    CHOICE=$(whiptail --title "MakaraSOC Deployment Menu" --menu "Choose an option:" 20 78 12 \
        "0" "Install Prerequisites" \
        "1" "Deploy Wazuh" \
        "2" "Deploy DFIR IRIS" \
        "3" "Deploy Shuffle" \
        "4" "Deploy MISP" \
        "5" "Deploy Velociraptor" \
        "6" "Deploy Yara" \
        "7" "Deploy OpenCTI" \
        "8" "Deploy Grafana" \
        "9" "Tools Configurations" \
        "10" "Return to Main Menu" 3>&1 1>&2 2>&3)

    case $CHOICE in
        0) log "Installing prerequisites..."; sudo ./install_prerequisites.sh ;;
        1) deploy_wazuh ;;
        2) deploy_iris ;;
        3) deploy_shuffle ;;
        4) deploy_misp ;;
        5) deploy_velociraptor ;;
        6) deploy_yara ;;
        7) deploy_opencti ;;
        8) deploy_grafana ;;
        9) tools_config ;;
        10) log "Returning to Main Menu."; break ;; # Exit manually menu
        *) log "Invalid option. Please try again." ;;
    esac
done
}

deploy_all_semiauto() {
while true; do
    CHOICE=$(whiptail --title "MakaraSOC Deployment Menu" --menu "Choose an option:" 20 78 12 \
        "1" "Deploy All Core services" \
        "2" "Tools Configurations" \
        "3" "Return to Main Menu" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) deploy_all ;;
        2) tools_config ;;
        3) log "Returning to Main Menu."; break ;; # Exit semiauto menu
        *) log "Invalid option. Please try again." ;;
    esac
done
}

#First Menu
while true; do
    CHOICE=$(whiptail --title "MakaraSOC Deployment Menu" --menu "Choose an option:" 20 78 12 \
        "1" "I'm New to This" \
        "2" "I Know What I'm Doing" \
        "3" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) deploy_all_semiauto ;;
        2) socarium_manual_config ;;
        3) log "Exiting menu."; exit 0 ;;
        *) log "Invalid option. Please try again." ;;
    esac
done

