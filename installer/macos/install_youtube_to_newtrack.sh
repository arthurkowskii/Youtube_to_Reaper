#!/bin/bash

# YouTube to New Track for REAPER - macOS Installer
# Version 2.0 - Multi-platform support (YouTube + SoundCloud)
# Author: Arthur Kowski

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME="YouTube_to_NewTrack.lua"
APP_NAME="YouTube to New Track for REAPER"
VERSION="2.0"

# Paths
REAPER_SCRIPTS_DIR="$HOME/Library/Application Support/REAPER/Scripts"
REAPER_PLUGINS_DIR="$HOME/Library/Application Support/REAPER/UserPlugins"
REAPER_RESOURCE_DIR="$HOME/Library/Application Support/REAPER"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR="/tmp/youtube_to_newtrack_install"

# Functions
print_header() {
    clear
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  $APP_NAME v$VERSION${NC}"
    echo -e "${BLUE}  macOS Installer${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_macos_version() {
    print_step "Checking macOS version..."
    local version=$(sw_vers -productVersion)
    local major_version=$(echo $version | cut -d. -f1)
    
    if [ "$major_version" -lt 10 ]; then
        print_error "macOS 10.10 or later required. Found: $version"
        exit 1
    fi
    
    print_success "macOS $version detected"
}

check_reaper_installation() {
    print_step "Checking REAPER installation..."
    
    # Check common REAPER locations
    local reaper_app="/Applications/REAPER.app"
    local reaper_64_app="/Applications/REAPER64.app"
    
    if [ -d "$reaper_app" ] || [ -d "$reaper_64_app" ]; then
        print_success "REAPER found in Applications folder"
        return 0
    fi
    
    # Check if user has run REAPER (resource directory exists)
    if [ -d "$REAPER_RESOURCE_DIR" ]; then
        print_success "REAPER resource directory found"
        return 0
    fi
    
    print_error "REAPER not found. Please install REAPER first."
    print_info "Download REAPER from: https://www.reaper.fm/download.php"
    exit 1
}

check_sws_extension() {
    print_step "Checking SWS Extension..."
    
    # Create UserPlugins directory if it doesn't exist
    mkdir -p "$REAPER_PLUGINS_DIR"
    
    # Check for SWS extension with different naming patterns
    local sws_patterns=(
        "reaper_sws.dylib"
        "reaper_sws64.dylib"
        "reaper_sws-x64.dylib"
        "reaper_sws_x64.dylib"
    )
    
    for pattern in "${sws_patterns[@]}"; do
        if [ -f "$REAPER_PLUGINS_DIR/$pattern" ]; then
            print_success "SWS Extension found: $pattern"
            return 0
        fi
    done
    
    print_error "SWS Extension not found"
    print_info "SWS Extension is required for clipboard functionality"
    
    read -p "Would you like to download SWS Extension now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "https://www.sws-extension.org/"
        print_info "Please download and install SWS Extension, then run this installer again"
        exit 1
    else
        print_info "Continuing without SWS Extension (clipboard functionality will not work)"
    fi
}

check_homebrew() {
    print_step "Checking Homebrew installation..."
    
    if command -v brew >/dev/null 2>&1; then
        print_success "Homebrew found"
        return 0
    fi
    
    print_error "Homebrew not found"
    print_info "Homebrew is the recommended way to install yt-dlp and ffmpeg"
    
    read -p "Would you like to install Homebrew now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ $(uname -m) == 'arm64' ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installed successfully"
    else
        print_info "Skipping Homebrew installation"
        return 1
    fi
}

install_dependencies() {
    print_step "Installing dependencies..."
    
    if command -v brew >/dev/null 2>&1; then
        print_step "Installing yt-dlp via Homebrew..."
        if ! brew list yt-dlp >/dev/null 2>&1; then
            brew install yt-dlp
            print_success "yt-dlp installed via Homebrew"
        else
            print_success "yt-dlp already installed"
        fi
        
        print_step "Installing ffmpeg via Homebrew..."
        if ! brew list ffmpeg >/dev/null 2>&1; then
            brew install ffmpeg
            print_success "ffmpeg installed via Homebrew"
        else
            print_success "ffmpeg already installed"
        fi
    else
        print_info "Homebrew not available, checking for manual installations..."
        
        # Check if yt-dlp is available
        if command -v yt-dlp >/dev/null 2>&1; then
            print_success "yt-dlp found in PATH"
        else
            print_error "yt-dlp not found"
            print_info "Please install yt-dlp manually or install Homebrew"
        fi
        
        # Check if ffmpeg is available
        if command -v ffmpeg >/dev/null 2>&1; then
            print_success "ffmpeg found in PATH"
        else
            print_error "ffmpeg not found"
            print_info "Please install ffmpeg manually or install Homebrew"
        fi
    fi
}

install_script() {
    print_step "Installing YouTube to New Track script..."
    
    # Create Scripts directory if it doesn't exist
    mkdir -p "$REAPER_SCRIPTS_DIR"
    
    # Get the directory where this installer is located
    local installer_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local source_script="$installer_dir/../../$SCRIPT_NAME"
    
    # Check if source script exists
    if [ ! -f "$source_script" ]; then
        print_error "Source script not found: $source_script"
        print_info "Please ensure $SCRIPT_NAME is in the correct location"
        exit 1
    fi
    
    # Copy script to REAPER Scripts directory
    cp "$source_script" "$REAPER_SCRIPTS_DIR/"
    
    if [ -f "$REAPER_SCRIPTS_DIR/$SCRIPT_NAME" ]; then
        print_success "Script installed to REAPER Scripts directory"
    else
        print_error "Failed to install script"
        exit 1
    fi
}

create_alias() {
    print_step "Creating desktop alias..."
    
    # Create an alias on Desktop pointing to the script
    local desktop_alias="$HOME/Desktop/YouTube to New Track Script"
    local target_script="$REAPER_SCRIPTS_DIR/$SCRIPT_NAME"
    
    # Remove existing alias if it exists
    [ -L "$desktop_alias" ] && rm "$desktop_alias"
    
    # Create symbolic link
    ln -s "$target_script" "$desktop_alias"
    
    if [ -L "$desktop_alias" ]; then
        print_success "Desktop alias created"
    else
        print_info "Could not create desktop alias"
    fi
}

show_post_install_instructions() {
    print_success "Installation completed successfully!"
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  NEXT STEPS TO ACTIVATE THE SCRIPT${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    echo "1. OPEN REAPER"
    echo "   - Launch REAPER from your Applications folder"
    echo ""
    echo "2. OPEN ACTION LIST"
    echo "   - Go to Actions → Show action list"
    echo "   - OR press the \"?\" key (question mark)"
    echo ""
    echo "3. LOAD THE SCRIPT"
    echo "   - Click \"New action...\" → \"Load ReaScript...\""
    echo "   - Navigate to: $REAPER_SCRIPTS_DIR"
    echo "   - Select \"$SCRIPT_NAME\" and click Open"
    echo ""
    echo "4. ASSIGN SHORTCUT (Optional)"
    echo "   - Select the script in the action list"
    echo "   - Click \"Add...\" to assign a keyboard shortcut"
    echo "   - Recommended: Cmd+Shift+Y"
    echo ""
    echo "5. TEST THE SCRIPT"
    echo "   - Copy a YouTube or SoundCloud URL to clipboard"
    echo "   - Run the script (use your shortcut or find it in action list)"
    echo "   - Watch the download progress window"
    echo ""
    echo -e "${GREEN}A \"YouTube to New Track Script\" alias has been placed on your desktop.${NC}"
    echo ""
    echo -e "${BLUE}For support: https://github.com/arthurkowskii/youtube_to_reaper${NC}"
    echo ""
}

# Main installation process
main() {
    print_header
    
    # Pre-flight checks
    check_macos_version
    check_reaper_installation
    check_sws_extension
    
    # Install dependencies
    if check_homebrew; then
        install_dependencies
    fi
    
    # Install the script
    install_script
    create_alias
    
    # Show completion message
    show_post_install_instructions
    
    echo -e "${GREEN}Thank you for using YouTube to New Track!${NC}"
}

# Check if running as root (not recommended)
if [ "$EUID" -eq 0 ]; then
    print_error "Do not run this installer as root/sudo"
    print_info "This installer will install files to your user directories"
    exit 1
fi

# Run main installation
main "$@"