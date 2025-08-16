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
