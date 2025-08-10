#!/bin/bash

# EmailForensics - Advanced Email Header Analysis Tool
# Automated Setup Script with GitHub Integration! 🚀

# Color definitions for fancy output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://github.com/coder5617/MailForensics"
PROJECT_NAME="EmailForensics"
DEFAULT_PORT=5000

# ASCII Art Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     📧 EmailForensics - Email Header Analyzer 📧            ║"
    echo "║          Advanced Security & Authentication Tool            ║"
    echo "║                    Version 2.0                               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Progress spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to print colored messages with emojis
print_message() {
    local color=$1
    local emoji=$2
    local message=$3
    echo -e "${color}${emoji} ${message}${NC}"
}

# Print section divider
print_section() {
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if running with proper permissions
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        print_message "$RED" "⚠️" "This script should not be run as root!"
        print_message "$YELLOW" "💡" "Run as regular user: ./setup.sh"
        exit 1
    fi
}

# Check for required tools
check_requirements() {
    print_section "🔍 System Requirements Check"
    
    local requirements=("docker" "docker-compose" "git" "curl")
    local missing=()
    
    for cmd in "${requirements[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
            print_message "$RED" "❌" "$cmd is not installed"
        else
            version=$($cmd --version 2>&1 | head -n1)
            print_message "$GREEN" "✅" "$cmd is installed: ${version}"
        fi
    done
    
    # Check Docker daemon
    if command -v docker &> /dev/null; then
        if ! docker info &> /dev/null; then
            print_message "$RED" "❌" "Docker daemon is not running"
            print_message "$YELLOW" "💡" "Start Docker: sudo systemctl start docker"
            missing+=("docker-daemon")
        else
            print_message "$GREEN" "✅" "Docker daemon is running"
        fi
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo
        print_message "$RED" "🛑" "Missing requirements detected!"
        print_message "$YELLOW" "📦" "Installation commands:"
        echo
        for item in "${missing[@]}"; do
            case $item in
                docker)
                    echo "  # Install Docker:"
                    echo "  curl -fsSL https://get.docker.com | sh"
                    echo "  sudo usermod -aG docker \$USER"
                    ;;
                docker-compose)
                    echo "  # Install Docker Compose:"
                    echo "  sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
                    echo "  sudo chmod +x /usr/local/bin/docker-compose"
                    ;;
                git)
                    echo "  # Install Git:"
                    echo "  sudo apt-get update && sudo apt-get install git -y"
                    ;;
                curl)
                    echo "  # Install Curl:"
                    echo "  sudo apt-get update && sudo apt-get install curl -y"
                    ;;
            esac
            echo
        done
        print_message "$RED" "❌" "Please install missing tools and run setup again"
        exit 1
    fi
    
    print_message "$GREEN" "🎉" "All requirements satisfied!"
}

# Check network connectivity
check_network() {
    print_section "🌐 Network Connectivity Check"
    
    print_message "$BLUE" "🔗" "Testing connection to GitHub..."
    if curl -s --head --request GET https://github.com > /dev/null; then
        print_message "$GREEN" "✅" "GitHub is reachable"
    else
        print_message "$RED" "❌" "Cannot reach GitHub - check your internet connection"
        exit 1
    fi
    
    print_message "$BLUE" "🔗" "Testing repository availability..."
    if git ls-remote "$GITHUB_REPO" HEAD &> /dev/null; then
        print_message "$GREEN" "✅" "Repository is accessible: $GITHUB_REPO"
    else
        print_message "$RED" "❌" "Cannot access repository: $GITHUB_REPO"
        print_message "$YELLOW" "💡" "Check if the repository URL is correct"
        exit 1
    fi
}

# Clone or update repository
setup_project() {
    print_section "📦 Project Setup"
    
    # Check if directory exists
    if [ -d "$PROJECT_NAME" ]; then
        print_message "$YELLOW" "📁" "Directory '$PROJECT_NAME' already exists"
        echo
        echo -e "${CYAN}Choose an option:${NC}"
        echo "  1) Update existing installation (git pull)"
        echo "  2) Backup and fresh install"
        echo "  3) Remove and fresh install"
        echo "  4) Cancel setup"
        echo
        read -p "$(echo -e ${CYAN}Select option [1-4]: ${NC})" choice
        
        case $choice in
            1)
                print_message "$BLUE" "🔄" "Updating existing installation..."
                cd "$PROJECT_NAME"
                git stash &> /dev/null
                git pull origin main || git pull origin master
                cd ..
                ;;
            2)
                backup_name="${PROJECT_NAME}_backup_$(date +%Y%m%d_%H%M%S)"
                print_message "$BLUE" "💾" "Creating backup: $backup_name"
                mv "$PROJECT_NAME" "$backup_name"
                clone_repository
                ;;
            3)
                print_message "$YELLOW" "⚠️" "Removing existing directory..."
                rm -rf "$PROJECT_NAME"
                clone_repository
                ;;
            4)
                print_message "$RED" "🚫" "Setup cancelled by user"
                exit 0
                ;;
            *)
                print_message "$RED" "❌" "Invalid option"
                exit 1
                ;;
        esac
    else
        clone_repository
    fi
}

# Clone repository function
clone_repository() {
    print_message "$BLUE" "📥" "Cloning repository from GitHub..."
    
    # Clone with progress
    git clone "$GITHUB_REPO" "$PROJECT_NAME" 2>&1 | while IFS= read -r line; do
        echo -e "${CYAN}    ${line}${NC}"
    done
    
    if [ $? -eq 0 ]; then
        print_message "$GREEN" "✅" "Repository cloned successfully!"
    else
        print_message "$RED" "❌" "Failed to clone repository"
        exit 1
    fi
}

# Configure environment
configure_environment() {
    print_section "⚙️ Environment Configuration"
    
    cd "$PROJECT_NAME"
    
    # Check for .env file
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_message "$BLUE" "📝" "Creating .env file from template..."
            cp .env.example .env
            print_message "$GREEN" "✅" ".env file created"
        else
            print_message "$BLUE" "📝" "Creating default .env file..."
            cat > .env << 'EOENV'
# EmailForensics Environment Configuration
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=$(openssl rand -hex 32)
IPINFO_API_KEY=
PORT=5000
EOENV
            print_message "$GREEN" "✅" ".env file created with defaults"
        fi
        
        print_message "$YELLOW" "💡" "You can add your IPInfo API key to .env for enhanced features"
    else
        print_message "$GREEN" "✅" ".env file already exists"
    fi
    
    # Check for Docker files
    if [ ! -f "Dockerfile" ]; then
        print_message "$YELLOW" "⚠️" "Dockerfile not found, creating one..."
        create_dockerfile
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        print_message "$YELLOW" "⚠️" "docker-compose.yml not found, creating one..."
        create_docker_compose
    fi
    
    cd ..
}

# Create Dockerfile if missing
create_dockerfile() {
    cat > Dockerfile << 'EODOCKER'
FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
EODOCKER
    print_message "$GREEN" "✅" "Dockerfile created"
}

# Create docker-compose.yml if missing
create_docker_compose() {
    cat > docker-compose.yml << EOCOMPOSE
version: '3.8'

services:
  emailforensics:
    build: .
    container_name: emailforensics_app
    ports:
      - "${DEFAULT_PORT}:5000"
    volumes:
      - ./logs:/app/logs
      - ./static:/app/static
      - ./templates:/app/templates
    environment:
      - FLASK_ENV=production
      - PYTHONUNBUFFERED=1
    restart: unless-stopped
    networks:
      - emailforensics_network

networks:
  emailforensics_network:
    driver: bridge
EOCOMPOSE
    print_message "$GREEN" "✅" "docker-compose.yml created"
}

# Check port availability
check_port() {
    print_section "🔌 Port Configuration"
    
    if lsof -Pi :$DEFAULT_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_message "$YELLOW" "⚠️" "Port $DEFAULT_PORT is already in use"
        read -p "$(echo -e ${CYAN}Enter alternative port number: ${NC})" new_port
        
        if [[ $new_port =~ ^[0-9]+$ ]] && [ $new_port -ge 1024 ] && [ $new_port -le 65535 ]; then
            DEFAULT_PORT=$new_port
            print_message "$GREEN" "✅" "Using port $DEFAULT_PORT"
            
            # Update docker-compose.yml with new port
            cd "$PROJECT_NAME"
            sed -i "s/5000:5000/$DEFAULT_PORT:5000/g" docker-compose.yml
            cd ..
        else
            print_message "$RED" "❌" "Invalid port number"
            exit 1
        fi
    else
        print_message "$GREEN" "✅" "Port $DEFAULT_PORT is available"
    fi
}

# Build Docker containers
build_docker() {
    print_section "🐳 Docker Build Process"
    
    cd "$PROJECT_NAME"
    
    print_message "$BLUE" "🔨" "Building Docker containers..."
    print_message "$YELLOW" "⏳" "This may take a few minutes..."
    
    # Build with output
    docker-compose build 2>&1 | while IFS= read -r line; do
        if [[ $line == *"ERROR"* ]]; then
            echo -e "${RED}    ${line}${NC}"
        elif [[ $line == *"WARNING"* ]]; then
            echo -e "${YELLOW}    ${line}${NC}"
        else
            echo -e "${CYAN}    ${line}${NC}"
        fi
    done
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_message "$GREEN" "✅" "Docker build successful!"
    else
        print_message "$RED" "❌" "Docker build failed!"
        print_message "$YELLOW" "💡" "Check the error messages above"
        exit 1
    fi
    
    cd ..
}

# Start the application
start_application() {
    print_section "🚀 Application Startup"
    
    cd "$PROJECT_NAME"
    
    print_message "$BLUE" "🎬" "Starting EmailForensics application..."
    
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        print_message "$GREEN" "✅" "Application started successfully!"
        
        # Wait for application to be ready
        print_message "$YELLOW" "⏳" "Waiting for application to initialize..."
        
        local max_attempts=30
        local attempt=0
        
        while [ $attempt -lt $max_attempts ]; do
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:$DEFAULT_PORT | grep -q "200"; then
                print_message "$GREEN" "🎊" "EmailForensics is ready!"
                break
            fi
            sleep 1
            attempt=$((attempt + 1))
            echo -n "."
        done
        echo
        
        if [ $attempt -eq $max_attempts ]; then
            print_message "$YELLOW" "⚠️" "Application may still be starting..."
            print_message "$CYAN" "💡" "Check logs with: docker logs emailforensics_app"
        fi
    else
        print_message "$RED" "❌" "Failed to start application!"
        exit 1
    fi
    
    cd ..
}

# Display access information
display_info() {
    print_section "📋 Access Information"
    
    local ip_address=$(hostname -I | awk '{print $1}')
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  ${WHITE}🌐 EmailForensics is now running!${CYAN}                          ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  ${WHITE}Access URLs:${CYAN}                                               ║${NC}"
    echo -e "${CYAN}║  ${GREEN}• Local:${WHITE}      http://localhost:$DEFAULT_PORT${CYAN}                      ║${NC}"
    echo -e "${CYAN}║  ${GREEN}• Network:${WHITE}    http://$ip_address:$DEFAULT_PORT${CYAN}                      ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  ${WHITE}Useful Commands:${CYAN}                                           ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}• View logs:${NC}     docker logs emailforensics_app${CYAN}            ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}• Stop app:${NC}      cd $PROJECT_NAME && docker-compose down${CYAN}    ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}• Restart:${NC}       cd $PROJECT_NAME && docker-compose restart${CYAN} ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}• Verify:${NC}        ./verify_deployment.sh${CYAN}                    ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# Copy verification script
setup_verification() {
    print_section "🔧 Additional Tools Setup"
    
    print_message "$BLUE" "📝" "Setting up verification script..."
    
    # The verify_deployment.sh should be in the repo, but if not, offer to download
    if [ ! -f "verify_deployment.sh" ]; then
        print_message "$YELLOW" "💾" "Creating verification script..."
        # Create a basic verification script if not in repo
        cat > verify_deployment.sh << 'EOVERIFY'
#!/bin/bash
echo "🔍 EmailForensics Verification"
echo "Checking deployment status..."
if docker ps | grep emailforensics_app > /dev/null; then
    echo "✅ Container is running"
    curl -s http://localhost:5000 > /dev/null && echo "✅ Application is accessible" || echo "❌ Application not responding"
else
    echo "❌ Container is not running"
fi
EOVERIFY
        chmod +x verify_deployment.sh
        print_message "$GREEN" "✅" "Verification script created"
    fi
}

# Main execution
main() {
    clear
    print_banner
    
    print_message "$PURPLE" "🎯" "Starting EmailForensics Setup Process..."
    print_message "$CYAN" "📦" "Repository: $GITHUB_REPO"
    echo
    
    # Run setup steps
    check_permissions
    check_requirements
    check_network
    setup_project
    configure_environment
    check_port
    
    echo
    print_message "$YELLOW" "🔄" "Ready to build and deploy EmailForensics!"
    read -p "$(echo -e ${CYAN}❓ Continue with Docker build and deployment? [Y/n]: ${NC})" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_message "$YELLOW" "⏸️" "Setup complete! Run 'cd $PROJECT_NAME && docker-compose up' when ready."
    else
        build_docker
        start_application
        display_info
    fi
    
    setup_verification
    
    echo
    print_message "$GREEN" "✨" "EmailForensics setup completed successfully!"
    print_message "$PURPLE" "🔐" "Happy email forensics analyzing!"
    echo
}

# Run main function
main