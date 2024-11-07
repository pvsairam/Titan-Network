#!/bin/bash

BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "  _______ _ _                 ______    _"            
    echo " |__   __(_) |               |  ____|  | |"           
    echo "    | |   _| |_ __ _ _ __    | |__   __| | __ _  ___" 
    echo "    | |  | | __/ _\` | '_ \   |  __| / _\` |/ _\` |/ _ \\"
    echo "    | |  | | || (_| | | | |  | |___| (_| | (_| |  __/"
    echo "    |_|  |_|\__\__,_|_| |_|  |______\__,_|\__, |\___|"
    echo "                                            __/ |"     
    echo "                                           |___/"      
    echo
    echo "                Titan Edge Installer v1.0"
    echo "                Author: Galkurta"
    echo -e "${NC}\n"
}

print_msg() {
    echo -e "  ${BLUE}→${NC} $1"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "  ${RED}×${NC} $1"
    exit 1
}

install_docker() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    else
        print_error "Cannot detect OS"
    fi

    case $OS in
        *"Ubuntu"*|*"Debian"*)
            print_msg "Installing Docker..."
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release >/dev/null 2>&1
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update >/dev/null 2>&1
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
            ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*)
            print_msg "Installing Docker..."
            sudo yum install -y yum-utils >/dev/null 2>&1
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
            sudo yum install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            ;;
    esac

    sudo systemctl start docker >/dev/null 2>&1
    sudo systemctl enable docker >/dev/null 2>&1
    sudo usermod -aG docker $USER >/dev/null 2>&1
    
    print_success "Docker installation completed"
    echo
}

print_banner

if [ "$EUID" -ne 0 ]; then
    print_error "Please run with sudo privileges"
fi

echo -e "  ${BLUE}Checking system requirements...${NC}"
if ! command -v docker &> /dev/null; then
    print_msg "Docker not found. Starting installation..."
    echo
    install_docker
else
    print_success "Docker already installed"
    echo
fi

while true; do
    echo -en "  ${BLUE}Enter your hash:${NC} "
    read HASH
    if [ ! -z "$HASH" ]; then
        break
    fi
    print_msg "Hash cannot be empty"
done

API_URL="https://api-test1.container1.titannet.io/api/v2/device/binding"

print_msg "Installing Titan Edge..."

docker pull nezha123/titan-edge >/dev/null 2>&1 || print_error "Failed to pull Docker image"

mkdir -p ~/.titanedge
docker run --network=host -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge >/dev/null 2>&1 || print_error "Failed to start container"

docker run --rm -it -v ~/.titanedge:/root/.titanedge nezha123/titan-edge bind --hash="$HASH" "$API_URL"

if [ $? -eq 0 ]; then
    echo
    print_msg "Installation complete! Titan Edge is now running."
else
    print_error "Installation failed. Please check your hash and try again."
fi