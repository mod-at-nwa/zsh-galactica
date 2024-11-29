#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
CONFIG_DIR="$HOME/.config/zsh-galactica"
ROLES_DIR="$CONFIG_DIR/roles"
BACKUP_DIR="$CONFIG_DIR/backup/$(date +%Y%m%d_%H%M%S)"
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
PLUGIN_DIR="$ZSH_CUSTOM/plugins/zsh-galactica"

# Function to print status messages
print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗${NC} $1"
    return 1
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Check for required dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for zsh
    if ! command -v zsh >/dev/null 2>&1; then
        missing_deps+=("zsh")
    fi
    
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    # Check for oh-my-zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_error "oh-my-zsh is not installed!"
        echo "Please install oh-my-zsh first: https://ohmyz.sh/#install"
        exit 1
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them using your package manager and try again."
        exit 1
    fi
    
    print_success "All dependencies found!"
}

# Backup existing configuration
backup_existing() {
    if [ -d "$CONFIG_DIR" ]; then
        print_status "Backing up existing configuration..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$CONFIG_DIR"/* "$BACKUP_DIR" 2>/dev/null || true
        print_success "Backup created at $BACKUP_DIR"
    fi
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p "$CONFIG_DIR" || print_error "Failed to create $CONFIG_DIR"
    mkdir -p "$ROLES_DIR" || print_error "Failed to create $ROLES_DIR"
    mkdir -p "$PLUGIN_DIR" || print_error "Failed to create $PLUGIN_DIR"
    
    print_success "Directories created successfully!"
}

# Install roles
install_roles() {
    print_status "Installing roles..."
    
    # Copy roles from current directory to roles directory
    if [ -d "roles" ]; then
        cp -r roles/* "$ROLES_DIR/" || print_error "Failed to copy roles"
        print_success "Roles installed successfully!"
    else
        print_error "Roles directory not found in current location!"
        return 1
    fi
}

# Configure zsh
configure_zsh() {
    print_status "Configuring zsh..."
    
    # Check if plugin is already in .zshrc
    if ! grep -q "plugins=.*zsh-galactica" "$HOME/.zshrc"; then
        print_status "Adding zsh-galactica to plugins in .zshrc..."
        # Backup .zshrc
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        # Add plugin to existing plugins list
        sed -i.bak 's/plugins=(\([^)]*\))/plugins=(\1 zsh-galactica)/' "$HOME/.zshrc"
    fi
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    local status=0
    
    # Check directories
    [ -d "$CONFIG_DIR" ] || status=1
    [ -d "$ROLES_DIR" ] || status=1
    [ -d "$PLUGIN_DIR" ] || status=1
    
    # Check if roles were copied
    [ "$(ls -A $ROLES_DIR)" ] || status=1
    
    # Check plugin registration
    grep -q "plugins=.*zsh-galactica" "$HOME/.zshrc" || status=1
    
    if [ $status -eq 0 ]; then
        print_success "Installation verified successfully!"
    else
        print_error "Installation verification failed!"
        return 1
    fi
}

# Main installation process
main() {
    echo -e "${BOLD}Installing ZSH-Galactica...${NC}\n"
    
    check_dependencies || exit 1
    backup_existing
    create_directories
    install_roles
    configure_zsh
    verify_installation
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}${BOLD}Installation completed successfully!${NC}"
        echo -e "\nTo finish setup:"
        echo "1. Add your OpenAI API key to your .zshrc:"
        echo "   echo 'export OPENAI_API_KEY=your-key-here' >> ~/.zshrc"
        echo "2. Restart your shell or run:"
        echo "   source ~/.zshrc"
    else
        echo -e "\n${RED}${BOLD}Installation failed!${NC}"
        echo "Please check the error messages above and try again."
        exit 1
    fi
}

# Run the installer
main "$@"
