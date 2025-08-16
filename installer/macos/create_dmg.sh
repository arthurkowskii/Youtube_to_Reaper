#!/bin/bash

# Create DMG package for YouTube to New Track macOS installer
# Version 2.0

set -e

# Configuration
APP_NAME="YouTube to New Track"
VERSION="2.0"
DMG_NAME="YouTube_to_NewTrack_v2.0_macOS"
BACKGROUND_IMAGE="dmg_background.png"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DMG_DIR="$BUILD_DIR/dmg_contents"
OUTPUT_DIR="$SCRIPT_DIR/Output"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Clean and create build directories
print_step "Preparing build environment..."
rm -rf "$BUILD_DIR"
mkdir -p "$DMG_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy installer script
print_step "Copying installer files..."
cp "$SCRIPT_DIR/install_youtube_to_newtrack.sh" "$DMG_DIR/"
chmod +x "$DMG_DIR/install_youtube_to_newtrack.sh"

# Copy main script from parent directory
cp "$SCRIPT_DIR/../../YouTube_to_NewTrack.lua" "$DMG_DIR/"

# Copy documentation
cp "$SCRIPT_DIR/../../README.md" "$DMG_DIR/"
cp "$SCRIPT_DIR/../../LICENSE" "$DMG_DIR/"

# Create installation instructions
cat > "$DMG_DIR/Installation Instructions.txt" << 'EOF'
YouTube to New Track v2.0 - macOS Installation
==============================================

INSTALLATION STEPS:
1. Double-click "install_youtube_to_newtrack.sh" to run the installer
2. Follow the on-screen instructions
3. The installer will:
   - Check for REAPER installation
   - Verify SWS Extension (required for clipboard functionality)
   - Install yt-dlp and ffmpeg via Homebrew (if available)
   - Install the script to REAPER's Scripts directory
   - Create a desktop alias for easy access

MANUAL INSTALLATION (Alternative):
If the automated installer doesn't work:
1. Copy "YouTube_to_NewTrack.lua" to:
   ~/Library/Application Support/REAPER/Scripts/
2. Install dependencies manually:
   - Install Homebrew: https://brew.sh/
   - Run: brew install yt-dlp ffmpeg
   - Install SWS Extension: https://www.sws-extension.org/

ACTIVATING THE SCRIPT IN REAPER:
1. Open REAPER
2. Go to Actions → Show action list
3. Click "New action..." → "Load ReaScript..."
4. Navigate to the script and load it
5. Assign a keyboard shortcut (recommended: Cmd+Shift+Y)

USAGE:
1. Copy a YouTube or SoundCloud URL to clipboard
2. Run the script in REAPER
3. Watch the download progress window
4. Audio imports automatically as a new track

REQUIREMENTS:
- macOS 10.10 or later
- REAPER 7.0+ (tested on 7.42)
- SWS Extension (for clipboard functionality)
- yt-dlp and ffmpeg (for audio downloading)

For support: https://github.com/arthurkowskii/youtube_to_reaper
EOF

# Create uninstall script
cat > "$DMG_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# YouTube to New Track - Uninstaller for macOS

SCRIPT_NAME="YouTube_to_NewTrack.lua"
REAPER_SCRIPTS_DIR="$HOME/Library/Application Support/REAPER/Scripts"
DESKTOP_ALIAS="$HOME/Desktop/YouTube to New Track Script"

echo "YouTube to New Track - Uninstaller"
echo "=================================="
echo ""

# Remove script from REAPER Scripts directory
if [ -f "$REAPER_SCRIPTS_DIR/$SCRIPT_NAME" ]; then
    rm "$REAPER_SCRIPTS_DIR/$SCRIPT_NAME"
    echo "✓ Removed script from REAPER Scripts directory"
else
    echo "- Script not found in REAPER Scripts directory"
fi

# Remove desktop alias
if [ -L "$DESKTOP_ALIAS" ]; then
    rm "$DESKTOP_ALIAS"
    echo "✓ Removed desktop alias"
else
    echo "- Desktop alias not found"
fi

echo ""
echo "Uninstallation completed."
echo ""
echo "Note: Dependencies (yt-dlp, ffmpeg) were not removed."
echo "To remove them, run: brew uninstall yt-dlp ffmpeg"
echo ""
EOF

chmod +x "$DMG_DIR/uninstall.sh"

# Skip background image creation on Windows
print_info "Skipping background image creation (not needed for basic DMG)"

# Check if we're on macOS for DMG creation
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_step "Running on macOS - DMG creation available"
    
    # Check if create-dmg is available
    if command -v create-dmg >/dev/null 2>&1; then
    print_step "Creating DMG using create-dmg..."
    
    create-dmg \
        --volname "$APP_NAME v$VERSION" \
        --volicon "$SCRIPT_DIR/../../installer/icon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 80 \
        --icon "install_youtube_to_newtrack.sh" 150 200 \
        --icon "Installation Instructions.txt" 450 200 \
        --hide-extension "install_youtube_to_newtrack.sh" \
        --app-drop-link 450 200 \
        "$OUTPUT_DIR/$DMG_NAME.dmg" \
        "$DMG_DIR"
        
    else
        print_step "Creating DMG using hdiutil..."
    
    # Calculate size needed (in MB, with some padding)
    DMG_SIZE=$(du -sm "$DMG_DIR" | cut -f1)
    DMG_SIZE=$((DMG_SIZE + 50))  # Add 50MB padding
    
    # Create temporary DMG
    TEMP_DMG="$BUILD_DIR/temp.dmg"
    hdiutil create -srcfolder "$DMG_DIR" -volname "$APP_NAME v$VERSION" -fs HFS+ \
            -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "$TEMP_DMG"
    
    # Mount the temporary DMG
    MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | \
                egrep '^/dev/' | sed 1q | awk '{print $3}')
    
    # Set up the DMG appearance (if background image exists)
    if [ -f "$DMG_DIR/$BACKGROUND_IMAGE" ]; then
        cp "$DMG_DIR/$BACKGROUND_IMAGE" "$MOUNT_DIR/.background.png"
    fi
    
    # Create .DS_Store for custom view settings
    cat > "$MOUNT_DIR/.DS_Store_template" << 'EOF'
# Custom view settings would go here
# This is a simplified version - a real .DS_Store would be binary
EOF
    
    # Unmount and compress
    hdiutil detach "$MOUNT_DIR"
    hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$OUTPUT_DIR/$DMG_NAME.dmg"
    
        # Clean up
        rm "$TEMP_DMG"
    fi

else
    # Running on non-macOS system (like Windows)
    print_step "Creating installer package structure for macOS distribution..."
    
    # Create a distributable folder structure
    DIST_DIR="$OUTPUT_DIR/YouTube_to_NewTrack_v2.0_macOS_Package"
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"
    
    # Copy all files to distribution directory
    cp -r "$DMG_DIR/"* "$DIST_DIR/"
    
    # Create a README for macOS users
    cat > "$DIST_DIR/BUILD_DMG_ON_MACOS.md" << 'EOF'
# Building DMG on macOS

To create the final DMG package on a Mac:

1. Copy this entire folder to a macOS system
2. Open Terminal and navigate to this directory
3. Run: `chmod +x create_dmg.sh`
4. Run: `./create_dmg.sh`

Alternatively, you can run the installer directly:
1. Double-click `install_youtube_to_newtrack.sh`
2. Follow the on-screen instructions

The installer will work without creating a DMG package.
EOF
    
    print_success "macOS installer package created: $DIST_DIR"
    print_info "This package can be distributed to macOS users"
    print_info "Users can run install_youtube_to_newtrack.sh directly"
    print_info "Or build a DMG using create_dmg.sh on macOS"
fi

# Print success message based on what was created
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_success "DMG created: $OUTPUT_DIR/$DMG_NAME.dmg"
else
    print_success "macOS installer package ready for distribution"
fi

# Create distribution info
cat > "$OUTPUT_DIR/distribution_info.txt" << EOF
YouTube to New Track v$VERSION - macOS Distribution
==================================================

Package: $DMG_NAME.dmg
Created: $(date)
Size: $(du -h "$OUTPUT_DIR/$DMG_NAME.dmg" | cut -f1)

Contents:
- install_youtube_to_newtrack.sh (Main installer)
- YouTube_to_NewTrack.lua (Main script)
- uninstall.sh (Uninstaller)
- Installation Instructions.txt (Setup guide)
- README.md (Project documentation)
- LICENSE (MIT License)

Installation:
1. Mount the DMG
2. Run install_youtube_to_newtrack.sh
3. Follow the on-screen instructions

Requirements:
- macOS 10.10 or later
- REAPER 7.0+
- SWS Extension (installer will check/prompt)
- Homebrew (recommended for dependencies)

The installer will automatically:
- Detect REAPER installation
- Check for SWS Extension
- Install yt-dlp and ffmpeg via Homebrew
- Copy script to REAPER Scripts directory
- Create desktop alias

For support: https://github.com/arthurkowskii/youtube_to_reaper
EOF

print_success "Distribution package created successfully!"
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_info "DMG location: $OUTPUT_DIR/$DMG_NAME.dmg"
    if [ -f "$OUTPUT_DIR/$DMG_NAME.dmg" ]; then
        print_info "Size: $(du -h "$OUTPUT_DIR/$DMG_NAME.dmg" | cut -f1)"
    fi
else
    print_info "Package location: $OUTPUT_DIR/YouTube_to_NewTrack_v2.0_macOS_Package"
    print_info "Size: $(du -sh "$OUTPUT_DIR/YouTube_to_NewTrack_v2.0_macOS_Package" | cut -f1)"
fi

# Clean up build directory
rm -rf "$BUILD_DIR"

echo ""
echo -e "${GREEN}macOS installer package ready for distribution!${NC}"