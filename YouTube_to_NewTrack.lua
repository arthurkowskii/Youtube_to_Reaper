-- YouTube → New Track v1.2 - Real-time Progress Bar
-- Background download with live progress indication using defer + gfx
-- Requires: SWS Extension, yt-dlp.exe, ffmpeg.exe
-- Compatible with REAPER 7.0+

-- Global variables for progress tracking
local download_active = false
local output_file = ""
local start_time = 0
local estimated_size = 5 * 1024 * 1024 -- Default 5MB estimate
local url = ""
local ytdlp_path = ""
local ffmpeg_path = ""
local progress_step = 0

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
url = clipboard:match("^%s*(.-)%s*$")

-- Extract just the YouTube URL if there's extra text
local youtube_url = url:match("(https?://[%w%.%-_]*youtube[%w%.%-_/?=&]*)")
if not youtube_url then
    youtube_url = url:match("(https?://youtu%.be/[%w%-_?=&]*)")
end
if youtube_url then
    url = youtube_url
end

reaper.ShowConsoleMsg("✓ Found YouTube URL: " .. url .. "\n")

-- Find yt-dlp executable
local function find_executable(name)
    local userprofile = os.getenv("USERPROFILE") or ""
    local localappdata = os.getenv("LOCALAPPDATA") or ""
    
    local common_paths = {
        userprofile .. "\\AppData\\Local\\Microsoft\\WinGet\\Packages\\yt-dlp.yt-dlp_Microsoft.Winget.Source_8wekyb3d8bbwe\\" .. name,
        userprofile .. "\\AppData\\Local\\Microsoft\\WinGet\\Links\\" .. name,
        localappdata .. "\\Microsoft\\WinGet\\Links\\" .. name,
        "C:\\Program Files\\yt-dlp\\" .. name,
        "C:\\Program Files (x86)\\yt-dlp\\" .. name,
        "C:\\Tools\\" .. name,
        "C:\\ffmpeg\\bin\\" .. name,
        "C:\\yt-dlp\\" .. name
    }
    
    for _, path in ipairs(common_paths) do
        if reaper.file_exists(path) then
            return path
        end
    end
    
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
reaper.ShowConsoleMsg("✓ Locating download tools...\n")
ytdlp_path = find_executable("yt-dlp.exe")
ffmpeg_path = find_executable("ffmpeg.exe")

if not ytdlp_path then
    reaper.ShowConsoleMsg("ERROR: yt-dlp.exe not found\n")
    return
end

if not ffmpeg_path then
    reaper.ShowConsoleMsg("ERROR: ffmpeg.exe not found\n")
    return
end

-- Setup progress window
gfx.init("YouTube Download Progress", 400, 120)
gfx.setfont(1, "Arial", 14)

-- Get temporary directory and create output filename  
local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "C:\\temp"
output_file = temp_dir .. "\\youtube_audio_" .. os.time() .. ".wav"

-- Create VBScript for truly asynchronous execution
local vbs_file = temp_dir .. "\\youtube_download_" .. os.time() .. ".vbs"
local cmd = string.format('"%s" -f bestaudio --extract-audio --audio-format wav --ffmpeg-location "%s" -o "%s" "%s"',
    ytdlp_path, ffmpeg_path, output_file, url)

-- Write VBScript that runs the command without blocking
local vbs_content = string.format([[
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "%s", 0, False
]], cmd:gsub('"', '""')) -- Escape quotes for VBScript

local vbs = io.open(vbs_file, "w")
if vbs then
    vbs:write(vbs_content)
    vbs:close()
else
    reaper.ShowConsoleMsg("ERROR: Cannot create VBScript file\n")
    return
end

-- Start background download
start_time = reaper.time_precise()
download_active = true
reaper.ShowConsoleMsg("✓ Starting background download...\n")

-- Execute VBScript using start command to avoid blocking
os.execute('start /B cscript //nologo "' .. vbs_file .. '"')

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
    
    -- Draw title
    gfx.set(1, 1, 1) -- White text
    gfx.x, gfx.y = 10, 10
    gfx.drawstr("YouTube Download in Progress...")
    
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
    
    -- Clean up VBScript file
    os.remove(vbs_file)
    
    -- Import the audio
    reaper.ShowConsoleMsg("✓ Download complete, importing to new track...\n")
    
    reaper.Undo_BeginBlock2(0)
    reaper.PreventUIRefresh(1)
    
    local insert_result = reaper.InsertMedia(output_file, 1)
    
    os.remove(output_file)
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, "Import YouTube audio", -1)
    
    -- Close progress window
    gfx.quit()
    
    if insert_result > 0 then
        reaper.ShowConsoleMsg("✓ SUCCESS: YouTube audio imported to new track!\n")
    else
        reaper.ShowConsoleMsg("✗ ERROR: Failed to import audio file\n")
    end
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
    
    reaper.ShowConsoleMsg("✗ ERROR: " .. reason .. "\n")
    
    -- Clean up
    if reaper.file_exists(vbs_file) then
        os.remove(vbs_file)
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