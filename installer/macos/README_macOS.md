# YouTube to New Track - macOS Installer

This directory contains the macOS installer for YouTube to New Track v2.0.

## Features

The macOS installer provides the same functionality as the Windows installer:

- ✅ **Automatic REAPER Detection** - Finds REAPER in standard locations
- ✅ **SWS Extension Verification** - Checks for required SWS extension with all naming patterns
- ✅ **Dependency Management** - Installs yt-dlp and ffmpeg via Homebrew
- ✅ **Script Installation** - Copies script to REAPER Scripts directory
- ✅ **Desktop Alias** - Creates easy access shortcut
- ✅ **Post-Install Instructions** - Clear 5-step activation guide
- ✅ **Uninstaller** - Clean removal option included

## Files

- `install_youtube_to_newtrack.sh` - Main installer script
- `create_dmg.sh` - DMG package builder
- `README_macOS.md` - This documentation

## Building the DMG Package

To create a distributable DMG package:

```bash
cd installer/macos
chmod +x create_dmg.sh
./create_dmg.sh
```

This will create `YouTube_to_NewTrack_v2.0_macOS.dmg` in the `Output/` directory.

## Installation Process

1. **Pre-flight Checks**:
   - Verifies macOS 10.10 or later
   - Detects REAPER installation
   - Checks for SWS Extension (all naming patterns)
   - Offers to install missing components

2. **Dependency Installation**:
   - Checks for Homebrew (offers to install if missing)
   - Installs yt-dlp via Homebrew
   - Installs ffmpeg via Homebrew
   - Falls back to manual installation prompts

3. **Script Installation**:
   - Creates REAPER Scripts directory if needed
   - Copies `YouTube_to_NewTrack.lua` to correct location
   - Creates desktop alias for easy access

4. **Post-Installation**:
   - Shows detailed activation instructions
   - Provides troubleshooting information
   - Creates uninstaller for clean removal

## Supported Paths

The installer automatically detects and uses standard macOS paths:

- **REAPER Scripts**: `~/Library/Application Support/REAPER/Scripts`
- **REAPER Plugins**: `~/Library/Application Support/REAPER/UserPlugins`
- **SWS Extension**: `~/Library/Application Support/REAPER/UserPlugins/reaper_sws*.dylib`

## SWS Extension Detection

The installer checks for all possible SWS extension naming patterns:
- `reaper_sws.dylib`
- `reaper_sws64.dylib`
- `reaper_sws-x64.dylib`
- `reaper_sws_x64.dylib`

## Dependencies

### Required
- **REAPER 7.0+** - DAW software
- **SWS Extension** - For clipboard functionality

### Recommended
- **Homebrew** - Package manager for easy dependency installation
- **yt-dlp** - YouTube/SoundCloud downloader
- **ffmpeg** - Audio processing

### Optional Tools
- **create-dmg** - For creating fancy DMG packages (falls back to hdiutil)
- **ImageMagick** - For creating DMG background images

## Manual Installation

If the automated installer doesn't work, users can install manually:

1. Copy `YouTube_to_NewTrack.lua` to `~/Library/Application Support/REAPER/Scripts/`
2. Install Homebrew: https://brew.sh/
3. Run: `brew install yt-dlp ffmpeg`
4. Install SWS Extension: https://www.sws-extension.org/

## Uninstallation

The DMG package includes an uninstaller that removes:
- Script from REAPER Scripts directory
- Desktop alias
- Does NOT remove dependencies (user choice)

## Security Notes

On macOS Catalina and later, users may need to:
1. Right-click the installer and select "Open"
2. Click "Open" in the security dialog
3. Or run: `xattr -d com.apple.quarantine install_youtube_to_newtrack.sh`

## Testing

The installer has been designed to work on:
- macOS 10.10 (Yosemite) and later
- Intel and Apple Silicon Macs
- Various REAPER installation configurations
- With and without Homebrew pre-installed

## Support

For issues with the macOS installer:
1. Check REAPER is installed in `/Applications/`
2. Verify SWS Extension is properly installed
3. Ensure Homebrew is working: `brew doctor`
4. Check script permissions: `ls -la ~/Library/Application\ Support/REAPER/Scripts/`

For general support: https://github.com/arthurkowskii/youtube_to_reaper