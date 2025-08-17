-- YouTube to New Track - DEBUG VERSION v2.0
-- This version logs every step to help diagnose issues on different systems
-- Use this version to troubleshoot problems with the main script

-- Create debug log function
local function debug_log(message)
    reaper.ShowConsoleMsg("[DEBUG] " .. message .. "\n")
end

debug_log("=== YouTube to New Track DEBUG VERSION ===")
debug_log("Script started at: " .. os.date())

-- Global variables for progress tracking
local download_active = false
local output_file = ""
local start_time = 0
local estimated_size = 5 * 1024 * 1024
local url = ""
local platform = ""
local ytdlp_path = ""
local ffmpeg_path = ""
local progress_step = 0

-- Step 1: Validate SWS extension
debug_log("Step 1: Checking SWS Extension...")
if not reaper.CF_GetClipboard then
    debug_log("ERROR: SWS Extension not detected! CF_GetClipboard function not available")
    debug_log("Please install SWS Extension from: https://www.sws-extension.org/")
    reaper.MB("SWS Extension not detected!\n\nPlease install SWS Extension from:\nhttps://www.sws-extension.org/", "Debug: Missing SWS", 0)
    return
end
debug_log("✓ SWS Extension detected successfully")

-- Step 2: Get clipboard content
debug_log("Step 2: Reading clipboard...")
local clipboard = reaper.CF_GetClipboard()
if not clipboard then
    debug_log("ERROR: Clipboard is nil")
    reaper.MB("Clipboard is empty or inaccessible", "Debug: Clipboard Issue", 0)
    return
end

if clipboard == "" then
    debug_log("ERROR: Clipboard is empty")
    reaper.MB("Clipboard is empty.\n\nPlease copy a YouTube or SoundCloud URL first.", "Debug: Empty Clipboard", 0)
    return
end

debug_log("✓ Clipboard content: " .. clipboard:sub(1, 100) .. (clipboard:len() > 100 and "..." or ""))

-- Step 3: Multi-platform URL detection
debug_log("Step 3: Detecting platform and URL...")

local function detect_platform_and_url(clipboard_content)
    debug_log("Analyzing clipboard content for URLs...")
    
    -- Clean clipboard content
    local clean_content = clipboard_content:match("^%s*(.-)%s*$")
    debug_log("Cleaned content length: " .. clean_content:len())
    
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
    
    -- Find the most recent valid URL
    local found_urls = {}
    
    for _, platform in ipairs(platforms) do
        debug_log("Checking " .. platform.name .. " patterns...")
        for _, pattern in ipairs(platform.patterns) do
            if clean_content:match(pattern) then
                debug_log("✓ Found " .. platform.name .. " domain match")
                for _, extractor in ipairs(platform.extractors) do
                    local extracted_url = clean_content:match(extractor)
                    if extracted_url then
                        debug_log("✓ Extracted URL: " .. extracted_url)
                        table.insert(found_urls, {platform = platform.name, url = extracted_url})
                    end
                end
            else
                debug_log("✗ No " .. platform.name .. " domain found")
            end
        end
    end
    
    debug_log("Total URLs found: " .. #found_urls)
    
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
    debug_log("ERROR: No supported URL found in clipboard")
    debug_log("Supported platforms: YouTube (youtube.com, youtu.be), SoundCloud (soundcloud.com)")
    reaper.MB("No YouTube or SoundCloud URL found in clipboard!\n\nSupported formats:\n• YouTube: youtube.com, youtu.be\n• SoundCloud: soundcloud.com\n\nCurrent clipboard:\n" .. clipboard:sub(1, 200), "Debug: No URL Found", 0)
    return
end

platform = detected_platform
url = detected_url
debug_log("✓ Platform detected: " .. platform)
debug_log("✓ URL extracted: " .. url)

-- Step 4: Find executables
debug_log("Step 4: Locating yt-dlp and ffmpeg...")

local function find_executable(name)
    debug_log("Searching for: " .. name)
    
    local userprofile = os.getenv("USERPROFILE") or ""
    local localappdata = os.getenv("LOCALAPPDATA") or ""
    
    debug_log("USERPROFILE: " .. userprofile)
    debug_log("LOCALAPPDATA: " .. localappdata)
    
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
    
    debug_log("Checking common installation paths...")
    for i, path in ipairs(common_paths) do
        debug_log("  [" .. i .. "] " .. path)
        if reaper.file_exists(path) then
            debug_log("  ✓ FOUND!")
            return path
        else
            debug_log("  ✗ Not found")
        end
    end
    
    -- Use where command
    debug_log("Trying 'where' command...")
    local test_cmd = 'where "' .. name .. '" 2>nul'
    debug_log("Command: " .. test_cmd)
    local result = reaper.ExecProcess(test_cmd, 5000)
    debug_log("Where result: " .. (result or "nil"))
    
    if result and result ~= "" and not result:match("Could not find") then
        local exe_path = result:match("^([^\r\n]+)")
        debug_log("Extracted path: " .. (exe_path or "nil"))
        if exe_path and reaper.file_exists(exe_path) then
            debug_log("✓ Found via WHERE command: " .. exe_path)
            return exe_path
        end
    end
    
    debug_log("✗ " .. name .. " not found anywhere")
    return nil
end

-- Locate tools
ytdlp_path = find_executable("yt-dlp.exe")
if not ytdlp_path then
    debug_log("ERROR: yt-dlp.exe not found!")
    reaper.MB("yt-dlp.exe not found!\n\nPlease install yt-dlp:\n• winget install yt-dlp\n• Or download from: https://github.com/yt-dlp/yt-dlp", "Debug: Missing yt-dlp", 0)
    return
end
debug_log("✓ yt-dlp found: " .. ytdlp_path)

ffmpeg_path = find_executable("ffmpeg.exe")
if not ffmpeg_path then
    debug_log("ERROR: ffmpeg.exe not found!")
    reaper.MB("ffmpeg.exe not found!\n\nPlease install ffmpeg:\n• winget install ffmpeg\n• Or download from: https://ffmpeg.org/", "Debug: Missing ffmpeg", 0)
    return
end
debug_log("✓ ffmpeg found: " .. ffmpeg_path)

-- Step 5: Setup and test file operations
debug_log("Step 5: Setting up file operations...")

local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "C:\\temp"
debug_log("Temp directory: " .. temp_dir)

-- Test temp directory write access
local test_file = temp_dir .. "\\debug_test_" .. os.time() .. ".tmp"
debug_log("Testing write access with: " .. test_file)

local test_handle = io.open(test_file, "w")
if not test_handle then
    debug_log("ERROR: Cannot write to temp directory!")
    reaper.MB("Cannot write to temp directory: " .. temp_dir .. "\n\nPlease check permissions.", "Debug: File Access Error", 0)
    return
end
test_handle:write("test")
test_handle:close()
os.remove(test_file)
debug_log("✓ Temp directory write access confirmed")

-- Create file paths
local platform_lower = platform:lower()
output_file = temp_dir .. "\\" .. platform_lower .. "_audio_" .. os.time() .. ".wav"
local vbs_file = temp_dir .. "\\" .. platform_lower .. "_download_" .. os.time() .. ".vbs"

debug_log("Output file: " .. output_file)
debug_log("VBS file: " .. vbs_file)

-- Step 6: Create and test VBScript
debug_log("Step 6: Creating VBScript...")

local cmd = string.format('"%s" -f bestaudio --extract-audio --audio-format wav --ffmpeg-location "%s" -o "%s" "%s"',
    ytdlp_path, ffmpeg_path, output_file, url)
    
debug_log("Download command: " .. cmd)

local vbs_content = string.format([[
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "%s", 0, False
]], cmd:gsub('"', '""'))

debug_log("Writing VBScript...")
local vbs = io.open(vbs_file, "w")
if not vbs then
    debug_log("ERROR: Cannot create VBScript file!")
    reaper.MB("Cannot create VBScript file: " .. vbs_file .. "\n\nPlease check permissions.", "Debug: VBScript Creation Failed", 0)
    return
end

vbs:write(vbs_content)
vbs:close()
debug_log("✓ VBScript created successfully")

-- Step 7: Setup progress window and start download
debug_log("Step 7: Starting download...")

-- Setup progress window
gfx.init("YouTube Download Progress - DEBUG", 400, 150)
gfx.setfont(1, "Arial", 12)

start_time = reaper.time_precise()
download_active = true

debug_log("Executing VBScript...")
local exec_cmd = 'start /B wscript //nologo "' .. vbs_file .. '"'
debug_log("Exec command: " .. exec_cmd)
os.execute(exec_cmd)

debug_log("✓ Download started - monitoring progress...")

-- Progress monitoring with debug info
local function monitor_progress()
    if not download_active then
        return
    end
    
    -- Clear window
    gfx.set(0.1, 0.1, 0.1)
    gfx.rect(0, 0, gfx.w, gfx.h)
    
    -- Check file status
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
    
    -- Draw debug info
    gfx.set(1, 1, 1)
    gfx.x, gfx.y = 10, 10
    gfx.drawstr("DEBUG: Downloading from " .. platform .. "...")
    
    gfx.x, gfx.y = 10, 25
    gfx.drawstr(string.format("Time: %.1fs | File exists: %s", elapsed, file_exists and "YES" or "NO"))
    
    if current_size > 0 then
        gfx.x, gfx.y = 10, 40
        local size_mb = current_size / (1024*1024)
        gfx.drawstr(string.format("Size: %.1f MB", size_mb))
        
        -- Progress bar
        local progress = math.min(current_size / estimated_size, 1.0)
        local bar_width = 360
        local bar_height = 15
        local bar_x, bar_y = 10, 60
        
        gfx.set(0.3, 0.3, 0.3)
        gfx.rect(bar_x, bar_y, bar_width, bar_height)
        
        gfx.set(0.2, 0.7, 0.2)
        gfx.rect(bar_x, bar_y, bar_width * progress, bar_height)
        
        gfx.set(1, 1, 1)
        gfx.x, gfx.y = bar_x + 5, bar_y + 2
        gfx.drawstr(string.format("%.0f%%", progress * 100))
    else
        gfx.x, gfx.y = 10, 40
        local dots = string.rep(".", (progress_step % 10) + 1)
        gfx.drawstr("Initializing" .. dots)
    end
    
    -- Debug info
    gfx.set(0.8, 0.8, 0.8)
    gfx.x, gfx.y = 10, 85
    gfx.drawstr("Output: " .. output_file:sub(-50))
    
    gfx.x, gfx.y = 10, 100
    gfx.drawstr("VBS: " .. vbs_file:sub(-50))
    
    gfx.x, gfx.y = 10, 115
    gfx.drawstr("Check console for detailed logs")
    
    gfx.x, gfx.y = 10, 130
    gfx.drawstr("Close this window to stop monitoring")
    
    gfx.update()
    
    -- Check if window was closed
    if gfx.getchar() == 27 or gfx.getchar() == -1 then -- ESC or window close
        debug_log("User closed progress window - stopping")
        download_active = false
        gfx.quit()
        return
    end
    
    -- Check completion
    if file_exists and current_size > 1024 and elapsed > 3 then
        reaper.defer(function()
            local file_handle2 = io.open(output_file, "rb")
            if file_handle2 then
                local size2 = file_handle2:seek("end")
                file_handle2:close()
                
                if size2 == current_size then
                    debug_log("Download appears complete - file stopped growing")
                    download_complete()
                else
                    debug_log("File still growing: " .. size2 .. " bytes")
                    reaper.defer(monitor_progress)
                end
            else
                reaper.defer(monitor_progress)
            end
        end)
        return
    end
    
    -- Check timeout
    if elapsed > 300 then
        debug_log("Download timeout after 5 minutes")
        download_failed("Timeout after 5 minutes")
        return
    end
    
    reaper.defer(monitor_progress)
end

-- Completion handler
function download_complete()
    debug_log("=== DOWNLOAD COMPLETE ===")
    download_active = false
    
    gfx.set(0.1, 0.1, 0.1)
    gfx.rect(0, 0, gfx.w, gfx.h)
    gfx.set(0.2, 0.8, 0.2)
    gfx.x, gfx.y = 10, 60
    gfx.drawstr("✓ Download Complete! Importing to REAPER...")
    gfx.update()
    
    -- Clean up VBScript
    if reaper.file_exists(vbs_file) then
        os.remove(vbs_file)
        debug_log("VBScript cleaned up")
    end
    
    -- Import audio
    debug_log("Importing audio file to REAPER...")
    reaper.Undo_BeginBlock2(0)
    reaper.PreventUIRefresh(1)
    
    local insert_result = reaper.InsertMedia(output_file, 1)
    debug_log("InsertMedia result: " .. tostring(insert_result))
    
    -- Clean up audio file
    if reaper.file_exists(output_file) then
        os.remove(output_file)
        debug_log("Audio file cleaned up")
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, "Import " .. platform .. " audio", -1)
    
    debug_log("=== IMPORT COMPLETE ===")
    
    gfx.quit()
end

-- Failure handler
function download_failed(reason)
    debug_log("=== DOWNLOAD FAILED: " .. reason .. " ===")
    download_active = false
    
    gfx.set(0.1, 0.1, 0.1)
    gfx.rect(0, 0, gfx.w, gfx.h)
    gfx.set(0.8, 0.2, 0.2)
    gfx.x, gfx.y = 10, 60
    gfx.drawstr("✗ Download Failed: " .. reason)
    gfx.update()
    
    -- Clean up
    if reaper.file_exists(vbs_file) then
        os.remove(vbs_file)
    end
    if reaper.file_exists(output_file) then
        os.remove(output_file)
    end
    
    reaper.defer(function()
        gfx.quit()
    end)
end

debug_log("Starting progress monitoring...")
reaper.defer(monitor_progress)