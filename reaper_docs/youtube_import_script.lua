-- Reaper script to download audio from a YouTube link using yt-dlp and import it into a new track.
-- Requires yt-dlp (or youtube-dl) installed and available in the system PATH.
-- This script prompts the user for a YouTube URL and optional track name, downloads the audio
-- as a WAV file into the current project directory, then creates a new track and inserts the audio.

local proj_path = reaper.GetProjectPath("")

-- Ask user for YouTube URL and optional track name
local retval, userInput = reaper.GetUserInputs("YouTube Audio Import", 2,
    "Enter YouTube URL:,Track Name (optional):", "")
if not retval then return end

-- Split input into URL and track name (comma‑separated)
local url, track_name = userInput:match("([^,]+),?(.*)")

if not url or url == "" then
    reaper.ShowMessageBox("No URL provided!", "Error", 0)
    return
end

-- Derive a filename from the video ID or use the URL itself
local video_id = url:match("v=([^&]+)") or url
local filename = video_id .. ".wav"  -- downloaded audio extension

-- Build a shell command to download and extract audio with yt‑dlp
-- --extract-audio converts video to audio; --audio-format wav ensures .wav output
-- The output template specifies the destination directory and filename.
local cmd = string.format('yt-dlp --extract-audio --audio-format wav --output "%s/%s" "%s"', proj_path, filename, url)

-- Run the command (wait indefinitely)
local result = reaper.ExecProcess(cmd, 0)

-- Build full path to the downloaded file
local full_path = proj_path .. "/" .. filename

-- Verify the file was downloaded
if not reaper.file_exists(full_path) then
    reaper.ShowMessageBox("Download failed. Ensure yt-dlp is installed and in your PATH.", "Error", 0)
    return
end

-- Insert a new track at the end of the project
reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
local new_track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)

-- Set track name if provided
if track_name and track_name ~= "" then
    reaper.GetSetMediaTrackInfo_String(new_track, "P_NAME", track_name, true)
end

-- Create a media item and take, assign the downloaded audio source
local media_item = reaper.AddMediaItemToTrack(new_track)
local take = reaper.AddTakeToMediaItem(media_item)
local source = reaper.PCM_Source_CreateFromFile(full_path)
reaper.SetMediaItemTake_Source(take, source)

-- Set the media item length to match the source length
local source_length = reaper.GetMediaSourceLength(source)
reaper.SetMediaItemLength(media_item, source_length, false)

-- Build waveform peaks and refresh the arrange view
reaper.Main_OnCommand(40047, 0) -- Build missing peaks
reaper.Main_OnCommand(40375, 0) -- Force reload of peak cache
reaper.UpdateArrange()

reaper.ShowMessageBox("Audio imported from YouTube and added to new track.", "Success", 0)
