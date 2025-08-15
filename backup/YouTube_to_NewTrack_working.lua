-- YouTube → New Track
-- Reads YouTube URL from clipboard, downloads audio via yt-dlp, imports as new track
-- Requires: SWS Extension, yt-dlp.exe, ffmpeg.exe
-- Compatible with REAPER 7.0+

-- Validate SWS extension
if not reaper.CF_GetClipboard then
    reaper.ShowConsoleMsg("ERROR: SWS extension required for clipboard access\n")
    return
end

-- Get clipboard content
local clipboard = reaper.CF_GetClipboard()
if not clipboard or clipboard == "" then
    reaper.ShowConsoleMsg("ERROR: No content in clipboard\n")
    return
end

-- Validate YouTube URL
local is_youtube = clipboard:match("youtube%.com") or clipboard:match("youtu%.be")
if not is_youtube then
    reaper.ShowConsoleMsg("ERROR: Clipboard does not contain YouTube URL\n")
    return
end

-- Clean URL (remove extra whitespace and extract just the URL)
local url = clipboard:match("^%s*(.-)%s*$")

-- Extract just the YouTube URL if there's extra text
local youtube_url = url:match("(https?://[%w%.%-_]*youtube[%w%.%-_/?=&]*)")
if not youtube_url then
    youtube_url = url:match("(https?://youtu%.be/[%w%-_?=&]*)")
end
if youtube_url then
    url = youtube_url
end

reaper.ShowConsoleMsg("Found YouTube URL: " .. url .. "\n")

-- Find yt-dlp executable
local function find_executable(name)
    -- Get user profile for winget installations
    local userprofile = os.getenv("USERPROFILE") or ""
    local localappdata = os.getenv("LOCALAPPDATA") or ""
    
    local common_paths = {
        -- Winget typical locations
        userprofile .. "\\AppData\\Local\\Microsoft\\WinGet\\Packages\\yt-dlp.yt-dlp_Microsoft.Winget.Source_8wekyb3d8bbwe\\" .. name,
        userprofile .. "\\AppData\\Local\\Microsoft\\WinGet\\Links\\" .. name,
        localappdata .. "\\Microsoft\\WinGet\\Links\\" .. name,
        -- Standard locations
        "C:\\Program Files\\yt-dlp\\" .. name,
        "C:\\Program Files (x86)\\yt-dlp\\" .. name,
        "C:\\Tools\\" .. name,
        "C:\\ffmpeg\\bin\\" .. name,
        "C:\\yt-dlp\\" .. name
    }
    
    -- Check common paths
    for _, path in ipairs(common_paths) do
        if reaper.file_exists(path) then
            return path
        end
    end
    
    -- Try system PATH by testing with 'where' command
    local test_cmd = 'where "' .. name .. '"'
    local result = reaper.ExecProcess(test_cmd, 5000)
    if result and result ~= "" and not result:match("Could not find") then
        local exe_path = result:match("^([^\r\n]+)")
        if exe_path and reaper.file_exists(exe_path) then
            return exe_path
        end
    end
    
    return nil
end

-- Locate tools
local ytdlp_path = find_executable("yt-dlp.exe")
local ffmpeg_path = find_executable("ffmpeg.exe")

if not ytdlp_path then
    reaper.ShowConsoleMsg("ERROR: yt-dlp.exe not found. Install yt-dlp and ensure it's in PATH or common directories\n")
    return
end

if not ffmpeg_path then
    reaper.ShowConsoleMsg("ERROR: ffmpeg.exe not found. Install ffmpeg and ensure it's in PATH or common directories\n")
    return
end

reaper.ShowConsoleMsg("Using yt-dlp: " .. ytdlp_path .. "\n")
reaper.ShowConsoleMsg("Using ffmpeg: " .. ffmpeg_path .. "\n")

-- Get temporary directory and create output filename
local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "C:\\temp"
local output_file = temp_dir .. "\\youtube_audio_" .. os.time() .. ".wav"

-- Build yt-dlp command with Windows-safe quoting
local cmd = string.format('"%s" -f bestaudio --extract-audio --audio-format wav --ffmpeg-location "%s" -o "%s" "%s"',
    ytdlp_path, ffmpeg_path, output_file, url)

reaper.ShowConsoleMsg("Executing: " .. cmd .. "\n")

-- Execute download command with 60 second timeout
local result = reaper.ExecProcess(cmd, 60000)

-- Verify output file exists and has content
if not reaper.file_exists(output_file) then
    reaper.ShowConsoleMsg("ERROR: Download failed - output file not created\n")
    if result then
        reaper.ShowConsoleMsg("Command output: " .. result .. "\n")
    end
    return
end

-- Check file size
local file_handle = io.open(output_file, "rb")
if not file_handle then
    reaper.ShowConsoleMsg("ERROR: Cannot access downloaded file\n")
    return
end
local file_size = file_handle:seek("end")
file_handle:close()

if file_size <= 1024 then -- Less than 1KB indicates likely failure
    reaper.ShowConsoleMsg("ERROR: Downloaded file too small (" .. file_size .. " bytes)\n")
    os.remove(output_file)
    return
end

reaper.ShowConsoleMsg("Download successful (" .. file_size .. " bytes)\n")

-- Begin undo block
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

-- Import audio as new track using InsertMedia with mode=1
local insert_result = reaper.InsertMedia(output_file, 1)

-- Clean up temporary file
os.remove(output_file)

-- Finalize undo block and refresh UI
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Import YouTube audio", -1)

if insert_result > 0 then
    reaper.ShowConsoleMsg("SUCCESS: YouTube audio imported to new track\n")
else
    reaper.ShowConsoleMsg("ERROR: Failed to import audio file\n")
end