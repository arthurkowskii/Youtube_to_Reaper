# YouTube → New Track

A REAPER ReaScript that downloads audio from YouTube URLs and imports them directly as new tracks with real-time progress indication.

## Features

- 📋 **Clipboard Integration**: Automatically reads YouTube URLs from clipboard
- 🎯 **Real-time Progress Bar**: Live progress window showing download status
- 📊 **File Size Tracking**: Shows downloaded MB and estimated progress
- ⏱️ **Live Timer**: Displays elapsed time during download
- 🔄 **Non-blocking**: REAPER remains responsive during download
- ✅ **Automatic Import**: Creates new track and imports audio when complete
- 🧹 **Auto-cleanup**: Removes temporary files after import

## Requirements

- **REAPER 7.0+** (tested on 7.42)

## Installation

### For Windows Users (Recommended)
1. Download and run `YouTube_to_NewTrack_Setup.exe` from the releases
   - Automatically installs yt-dlp and ffmpeg dependencies
   - Installs the ReaScript in REAPER
   - Checks for and prompts to install SWS Extension if needed
   - Sets up everything you need in one click

### Manual Installation
For advanced users or other platforms:
1. Install [SWS Extension](https://sws-extension.org/) for REAPER
2. Download `YouTube_to_NewTrack.lua` and load it in REAPER:
   - Actions → Show Action List → ReaScript → Load
3. Ensure yt-dlp and ffmpeg are available in your system PATH

## Usage

1. Copy a YouTube URL to your clipboard
2. Run the script in REAPER
3. Watch the progress window while download happens
4. Audio automatically imports as a new track when complete

## Version History

- **v1.2** - Real-time progress bar with live updates
- **v1.1 Beta A** - Enhanced console feedback  
- **v1.0** - Basic working version (backed up in `/backup/`)

## Files

- `YouTube_to_NewTrack.lua` - Main script (v1.2)
- `YouTube_beta_A.lua` - Beta version with enhanced console feedback
- `YouTube_progress.lua` - Development version of progress implementation
- `backup/YouTube_to_NewTrack_working.lua` - Backup of v1.0
- `reaper_docs/` - REAPER API documentation and references

## Technical Details

- Uses VBScript wrapper for truly asynchronous download execution
- Monitors file growth in real-time via `reaper.defer()` loops  
- Progress estimation based on downloaded file size
- Automatic tool detection for winget installations
- Proper REAPER undo/redo integration

## License

MIT License - Feel free to use and modify!