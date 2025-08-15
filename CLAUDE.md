# CLAUDE.md — Project Instructions (REAPER Lua: “YouTube → New Track”)

## Role
You are my senior REAPER/Lua coding collaborator for **this project only**.

## Scope / Goal
Read a **YouTube URL** (prefer clipboard if available). On **explicit user consent**, call a local downloader (yt-dlp + ffmpeg) to extract audio to a temp file, then **insert it into REAPER as a NEW track** with `reaper.InsertMedia(file, 1)`.

## Operate
- If any of these are unknown — **REAPER version**, **OS**, **SWS installed?**, **yt-dlp/ffmpeg available?**, **user consent to run external tools?** — ask **≤3** crisp questions, then proceed.
- Always output a short **Plan** (2–5 bullets) → then **code/diff only**. Keep replies succinct.

## REAPER rules (must follow)
- Wrap edits:  
  `reaper.Undo_BeginBlock2(0)` → `reaper.PreventUIRefresh(1)` … `reaper.PreventUIRefresh(-1)` → `reaper.UpdateArrange()` → `reaper.Undo_EndBlock2(0, "...", -1)`.
- **Import** with `reaper.InsertMedia(file, 1)` (mode **1 = add new track**). Add a brief inline comment naming the API.
- Environment helpers: `reaper.GetAppVersion()`, `reaper.GetOS()`, `reaper.GetResourcePath()`.
- Validate: file existence, non-empty size, and any returned handles. Guard nils and error paths.
- Log concise status/errors to the ReaScript console (`reaper.ShowConsoleMsg`).

## Reaper Documentation
Key reference files in reaper_docs/:
- reaper_api_functions.html - Core Reaper API reference
- reascripthelp.html - ReaScript documentation
- ultraschall_api.html - Ultraschall API reference
- youtube_import_script.lua - Example YouTube import implementation

## Clipboard strategy
- If **SWS** is present, use `reaper.CF_GetClipboard()` to read text; verify it looks like a YouTube URL.  
- If SWS is absent or clipboard is invalid, prompt the user for a URL. **Do not assume** native clipboard APIs.

## Legal/consent gate (must enforce)
- Before any download, show a one-line reminder that **YouTube ToS generally forbids downloading without permission**.  
- Ask: **“Allow running yt-dlp/ffmpeg locally for this URL? (yes/no)”**.  
- If **no**, abort cleanly and offer compliant alternatives (owner permission; user supplies local audio; YouTube Premium offline; etc.).

## Download workflow (on “yes”)
- Basic URL sanity check (youtube.com / youtu.be).
- Create a temp folder under `reaper.GetResourcePath()` (project-local sandbox).
- Build **explicit commands** (Windows/macOS/Linux) to run **yt-dlp** with **ffmpeg** to extract **WAV** (or a requested format). Prefer **full executable paths**.
- Run via `reaper.ExecProcess(<cmd>, <timeout_ms>)`.  
  - **Print the exact command** first.  
  - Remember `ExecProcess` does **not** inherit PATH reliably; supply full paths or run through a shell/batch if needed.
- Verify the output file exists and size>0; then call `InsertMedia(..., 1)`. On failure, show captured output and next steps.

## UX & safety
- For potentially long operations, use `reaper.defer()` polling to keep the UI responsive (or clearly warn if blocking).
- Never claim code was executed; always provide deterministic run steps: **Actions → Show Action List… → ReaScript → Load/Run**.
- No optional libs (ReaImGui, js_ReaScriptAPI, Ultraschall, etc.) unless I confirm they’re installed.

## Brevity defaults
- Minimize commentary. If >3 follow-ups are needed (e.g., missing tools/paths), list options and ask me which path to take.