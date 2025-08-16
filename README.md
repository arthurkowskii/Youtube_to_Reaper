# Audio → New Track

A REAPER ReaScript that downloads audio from multiple platforms and imports them directly as new tracks with real-time progress indication.

## Supported Platforms

- 🎥 **YouTube** - Videos, playlists, and live streams
- 🎵 **SoundCloud** - Tracks and playlists

## Features

- 📋 **Smart URL Detection**: Automatically detects YouTube and SoundCloud URLs from clipboard
- 🎯 **Real-time Progress Bar**: Live progress window showing download status
- 📊 **File Size Tracking**: Shows downloaded MB and estimated progress
- ⏱️ **Live Timer**: Displays elapsed time during download
- 🔄 **Non-blocking**: REAPER remains responsive during download
- ✅ **Automatic Import**: Creates new track and imports audio when complete
- 🧹 **Auto-cleanup**: Removes temporary files after import
- 🔇 **Silent Operation**: No console output or command prompt windows
- 🏷️ **Platform-aware**: Shows which platform you're downloading from

## Requirements

- **REAPER 7.0+** (tested on 7.42)

## Installation

### For Windows Users (Recommended)
1. Download and run `Audio_to_NewTrack_Setup_v2.0.exe` from the [releases page](https://github.com/arthurkowskii/youtube_to_reaper/releases)
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

1. Copy a YouTube or SoundCloud URL to your clipboard
2. Run the "Audio to New Track" script in REAPER (find it in Actions → Show Action List)
3. Watch the platform-aware progress window while download happens
4. Audio automatically imports as a new track when complete

## Version History

- **v2.0** - Multi-platform support (YouTube + SoundCloud), silent operation, platform-specific features
- **v1.2** - Real-time progress bar with live updates
- **v1.1 Beta A** - Enhanced console feedback  
- **v1.0** - Basic working version

## Files

- `YouTube_to_NewTrack.lua` - Main script (v2.0)
- `installer/` - Windows installer and setup files
- `LICENSE` - MIT License
- `README.md` - This documentation

## Technical Details

- **Multi-platform URL detection** - Automatically identifies YouTube and SoundCloud URLs
- **VBScript wrapper** for truly asynchronous download execution
- **Hidden execution** - No command prompt windows or console output
- **Real-time monitoring** - File growth tracking via `reaper.defer()` loops  
- **Platform-specific optimization** - Different download strategies per platform
- **Smart file naming** - Platform-aware temporary file naming
- **Automatic tool detection** - Finds yt-dlp and ffmpeg from winget installations
- **Proper REAPER integration** - Full undo/redo support with platform-specific naming

## License

MIT License - Feel free to use and modify!