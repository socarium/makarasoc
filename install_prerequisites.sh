#!/bin/bash
set -e  # Exit on any error

install_prerequisites() {
    echo "🛠 Installing prerequisites..."
    sudo apt install -y git curl wget python3-pip whiptail jq openjdk-18-jre-headless|| error_handler "Prerequisites Installation"
}

echo "=============================="
echo "Docker & Docker-Compose Setup"
echo "=============================="

# Step 1: Install Python
echo "Installing python packages..."
sudo apt install python3-pip -y
sudo apt install python3-venv -y
python3 -m venv venv
source venv/bin/activate
python3 -m pip install wheel build
python3 -m pip install setuptools
deactivate
sleep 5  # Check every 5 seconds

# Step 2: Install required packages
echo "Installing required packages..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
sleep 5  # Check every 5 seconds

# Step 3: Add Docker’s official GPG key
echo "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg --yes

# Step 4: Set up the Docker repository
echo "Setting up Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 5: Install Docker Engine
echo "Installing Docker Engine..."
sudo apt update
sleep 5  # Check every 5 seconds
sudo apt install -y docker-ce docker-ce-cli containerd.io
sleep 5  # Check every 5 seconds

# Step 6: Start and enable Docker service
echo "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Step 7: Add user to Docker group
echo "Adding user to Docker group..."
sudo usermod -aG docker $USER

# Step 8: Install Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Step 9: Verify installation
echo "Verifying installation..."
docker --version
docker-compose --version

# Step 10: Print success message
echo "====================================="
echo "Docker and Docker Compose are ready!"
echo "Log out and log back in for changes to take effect."
echo "====================================="
