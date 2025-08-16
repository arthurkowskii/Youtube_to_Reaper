#!/bin/bash

# YouTube to New Track for REAPER - macOS Single-File Installer
# Version 2.0 - Multi-platform support (YouTube + SoundCloud)
# Author: Arthur Kowski
# License: MIT

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

# Functions
print_header() {
    clear
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  $APP_NAME v$VERSION${NC}"
    echo -e "${BLUE}  macOS Single-File Installer${NC}"
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
    
    echo ""
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
    
    echo ""
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

extract_and_install_script() {
    print_step "Installing YouTube to New Track script..."
    
    # Create Scripts directory if it doesn't exist
    mkdir -p "$REAPER_SCRIPTS_DIR"
    
    # Extract the embedded Lua script and write it to the Scripts directory
    cat > "$REAPER_SCRIPTS_DIR/$SCRIPT_NAME" << 'EMBEDDED_LUA_SCRIPT'
-- Audio → New Track v2.0 - Multi-Platform Support (YouTube + SoundCloud)
-- Background download with live progress indication using defer + gfx
-- Supports: YouTube and SoundCloud URLs with platform detection
-- Features: Real-time progress, SoundCloud Go+ restriction warnings
-- Requires: SWS Extension, yt-dlp, ffmpeg
-- Compatible with REAPER 7.0+ (macOS)

-- Global variables for progress tracking
local download_active = false
local output_file = ""
local start_time = 0
local estimated_size = 5 * 1024 * 1024 -- Default 5MB estimate
local url = ""
local platform = ""
local ytdlp_path = ""
local ffmpeg_path = ""
local progress_step = 0
local restriction_warning = ""

-- Validate SWS extension
if not reaper.CF_GetClipboard then
    return
end

-- Get clipboard content
local clipboard = reaper.CF_GetClipboard()
if not clipboard or clipboard == "" then
    return
end

-- Multi-platform URL detection function
local function detect_platform_and_url(clipboard_content)
    -- Clean clipboard content
    local clean_content = clipboard_content:match("^%s*(.-)%s*$")
    
    -- Platform detection patterns
    local platforms = {
        {name = "YouTube", patterns = {"youtube%.com", "youtu%.be"}, 
         extractors = {
             "(https?://[%w%.%-_]*youtube[%w%.%-_/?=&]*)",
             "(https?://youtu%.be/[%w%-_?=&]*)"
         }},
        {name = "SoundCloud", patterns = {"soundcloud%.com"}, 
         extractors = {
             "(https?://soundcloud%.com/[%w%.%-_/?=&]*)"
         }}
    }
    
    -- Find the most recent valid URL by scanning from end to beginning
    local found_urls = {}
    
    for _, platform in ipairs(platforms) do
        for _, pattern in ipairs(platform.patterns) do
            if clean_content:match(pattern) then
                for _, extractor in ipairs(platform.extractors) do
                    local extracted_url = clean_content:match(extractor)
                    if extracted_url then
                        table.insert(found_urls, {platform = platform.name, url = extracted_url})
                    end
                end
            end
        end
    end
    
    if #found_urls == 0 then
        return nil, nil
    end
    
    -- Return the last found URL (most recent)
    local result = found_urls[#found_urls]
    return result.platform, result.url
end

-- Detect platform and extract URL
local detected_platform, detected_url = detect_platform_and_url(clipboard)
if not detected_platform then
    return
end

platform = detected_platform
url = detected_url

-- Find executable (macOS version)
local function find_executable(name)
    local home = os.getenv("HOME") or ""
    
    -- macOS common paths for Homebrew installations
    local common_paths = {
        "/opt/homebrew/bin/" .. name,  -- Apple Silicon Homebrew
        "/usr/local/bin/" .. name,     -- Intel Homebrew
        "/usr/bin/" .. name,           -- System installation
        home .. "/.local/bin/" .. name, -- User local installation
    }
    
    for _, path in ipairs(common_paths) do
        if reaper.file_exists(path) then
            return path
        end
    end
    
    -- Use which command to find in PATH
    local handle = io.popen("which " .. name .. " 2>/dev/null")
    if handle then
        local result = handle:read("*a")
        handle:close()
        if result and result ~= "" then
            local exe_path = result:match("^([^\r\n]+)")
            if exe_path and reaper.file_exists(exe_path) then
                return exe_path
            end
        end
    end
    
    return nil
end

-- Locate tools
ytdlp_path = find_executable("yt-dlp")
ffmpeg_path = find_executable("ffmpeg")

if not ytdlp_path then
    return
end

if not ffmpeg_path then
    return
end

-- Setup progress window
gfx.init("YouTube Download Progress", 400, 120)
gfx.setfont(1, "Arial", 14)

-- Get temporary directory and create output filename  
local temp_dir = os.getenv("TMPDIR") or "/tmp"
if temp_dir:sub(-1) == "/" then
    temp_dir = temp_dir:sub(1, -2) -- Remove trailing slash
end

local platform_lower = platform:lower()
output_file = temp_dir .. "/" .. platform_lower .. "_audio_" .. os.time() .. ".wav"

-- Create shell script for background execution on macOS
local script_file = temp_dir .. "/" .. platform_lower .. "_download_" .. os.time() .. ".sh"
local cmd = string.format('"%s" -f bestaudio --extract-audio --audio-format wav --ffmpeg-location "%s" -o "%s" "%s"',
    ytdlp_path, ffmpeg_path, output_file, url)

-- Write shell script
local script_content = string.format([[#!/bin/bash
%s > /dev/null 2>&1 &
]], cmd)

local script = io.open(script_file, "w")
if script then
    script:write(script_content)
    script:close()
    -- Make script executable
    os.execute("chmod +x '" .. script_file .. "'")
else
    return
end

-- Start background download
start_time = reaper.time_precise()
download_active = true

-- Execute script in background
os.execute("'" .. script_file .. "' &")

-- Progress monitoring function
local function monitor_progress()
    if not download_active then
        return
    end
    
    -- Clear window
    gfx.set(0.1, 0.1, 0.1) -- Dark background
    gfx.rect(0, 0, gfx.w, gfx.h)
    
    -- Check if file exists and get size
    local current_size = 0
    local file_exists = reaper.file_exists(output_file)
    
    if file_exists then
        local file_handle = io.open(output_file, "rb")
        if file_handle then
            current_size = file_handle:seek("end")
            file_handle:close()
        end
    end
    
    local elapsed = reaper.time_precise() - start_time
    progress_step = progress_step + 1
    
    -- Draw title with platform
    gfx.set(1, 1, 1) -- White text
    gfx.x, gfx.y = 10, 10
    gfx.drawstr("Downloading from " .. platform .. "...")
    
    -- Draw elapsed time
    gfx.x, gfx.y = 10, 30
    gfx.drawstr(string.format("Time: %.1fs", elapsed))
    
    -- Draw file size if available
    if current_size > 0 then
        gfx.x, gfx.y = 10, 50
        local size_mb = current_size / (1024*1024)
        gfx.drawstr(string.format("Downloaded: %.1f MB", size_mb))
        
        -- Simple progress estimation based on size growth
        local progress = math.min(current_size / estimated_size, 1.0)
        
        -- Draw progress bar
        local bar_width = 360
        local bar_height = 20
        local bar_x, bar_y = 10, 75
        
        -- Background bar
        gfx.set(0.3, 0.3, 0.3)
        gfx.rect(bar_x, bar_y, bar_width, bar_height)
        
        -- Progress fill
        gfx.set(0.2, 0.7, 0.2) -- Green
        gfx.rect(bar_x, bar_y, bar_width * progress, bar_height)
        
        -- Progress text
        gfx.set(1, 1, 1)
        gfx.x, gfx.y = bar_x + 5, bar_y + 3
        gfx.drawstr(string.format("%.0f%%", progress * 100))
        
    else
        -- Animated waiting indicator
        gfx.x, gfx.y = 10, 50
        local dots = string.rep(".", (progress_step % 10) + 1)
        gfx.drawstr("Initializing download" .. dots)
    end
    
    gfx.update()
    
    -- Check if download is complete
    if file_exists and current_size > 1024 then
        -- Wait a moment to ensure download is really complete
        if elapsed > 3 then -- At least 3 seconds
            -- Try to check if file is still growing
            reaper.defer(function()
                local file_handle2 = io.open(output_file, "rb")
                if file_handle2 then
                    local size2 = file_handle2:seek("end")
                    file_handle2:close()
                    
                    if size2 == current_size then
                        -- File stopped growing, download complete
                        download_complete()
                    else
                        -- Still growing, continue monitoring
                        reaper.defer(monitor_progress)
                    end
                else
                    reaper.defer(monitor_progress)
                end
            end)
            return
        end
    end
    
    -- Check timeout (5 minutes max)
    if elapsed > 300 then
        download_failed("Download timeout after 5 minutes")
        return
    end
    
    -- Continue monitoring
    reaper.defer(monitor_progress)
end

-- Download completion handler
function download_complete()
    download_active = false
    
    -- Update progress window
    gfx.set(0.1, 0.1, 0.1)
    gfx.rect(0, 0, gfx.w, gfx.h)
    gfx.set(0.2, 0.8, 0.2) -- Green
    gfx.x, gfx.y = 10, 40
    gfx.drawstr("Download Complete! Importing to REAPER...")
    gfx.update()
    
    -- Clean up script file
    os.remove(script_file)
    
    -- Import the audio
    reaper.Undo_BeginBlock2(0)
    reaper.PreventUIRefresh(1)
    
    local insert_result = reaper.InsertMedia(output_file, 1)
    
    os.remove(output_file)
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, "Import " .. platform .. " audio", -1)
    
    -- Close progress window
    gfx.quit()
end

-- Download failure handler
function download_failed(reason)
    download_active = false
    
    gfx.set(0.1, 0.1, 0.1)
    gfx.rect(0, 0, gfx.w, gfx.h)
    gfx.set(0.8, 0.2, 0.2) -- Red
    gfx.x, gfx.y = 10, 40
    gfx.drawstr("Download Failed: " .. reason)
    gfx.update()
    
    -- Clean up
    if reaper.file_exists(script_file) then
        os.remove(script_file)
    end
    if reaper.file_exists(output_file) then
        os.remove(output_file)
    end
    
    -- Keep window open for 3 seconds then close
    reaper.defer(function()
        gfx.quit()
    end)
end

-- Start monitoring
reaper.defer(monitor_progress)
EMBEDDED_LUA_SCRIPT
    
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

create_uninstaller() {
    print_step "Creating uninstaller..."
    
    cat > "$HOME/Desktop/Uninstall YouTube to New Track.sh" << 'UNINSTALLER_SCRIPT'
#!/bin/bash

# YouTube to New Track - Uninstaller for macOS

SCRIPT_NAME="YouTube_to_NewTrack.lua"
REAPER_SCRIPTS_DIR="$HOME/Library/Application Support/REAPER/Scripts"
DESKTOP_ALIAS="$HOME/Desktop/YouTube to New Track Script"
UNINSTALLER="$HOME/Desktop/Uninstall YouTube to New Track.sh"

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
echo "This uninstaller will self-destruct in 5 seconds..."

# Self-destruct countdown
for i in 5 4 3 2 1; do
    echo -n "$i... "
    sleep 1
done
echo ""

# Remove self
rm "$UNINSTALLER"
UNINSTALLER_SCRIPT

    chmod +x "$HOME/Desktop/Uninstall YouTube to New Track.sh"
    print_success "Uninstaller created on desktop"
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
    echo -e "${GREEN}Desktop shortcuts created:${NC}"
    echo -e "${GREEN}• \"YouTube to New Track Script\" (script access)${NC}"
    echo -e "${GREEN}• \"Uninstall YouTube to New Track.sh\" (uninstaller)${NC}"
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
    extract_and_install_script
    create_alias
    create_uninstaller
    
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