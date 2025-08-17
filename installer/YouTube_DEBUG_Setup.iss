[Setup]
AppName=YouTube to New Track - DEBUG VERSION
AppVersion=2.0-DEBUG
AppPublisher=Arthur Kowski
AppPublisherURL=https://github.com/arthurkowskii/youtube_to_reaper
AppSupportURL=https://github.com/arthurkowskii/youtube_to_reaper/issues
AppUpdatesURL=https://github.com/arthurkowskii/youtube_to_reaper/releases
DefaultDirName={autopf}\YouTube to New Track Debug
DefaultGroupName=YouTube to New Track Debug
AllowNoIcons=yes
LicenseFile=..\LICENSE
InfoBeforeFile=debug_installation_info.txt
OutputDir=Output
OutputBaseFilename=YouTube_DEBUG_Setup_v2.0
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full debug installation (includes all dependencies)"
Name: "minimal"; Description: "Debug script only"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "script"; Description: "YouTube to New Track DEBUG script (with detailed logging)"; Types: full minimal custom; Flags: fixed
Name: "ytdlp"; Description: "yt-dlp (YouTube downloader)"; Types: full
Name: "ffmpeg"; Description: "FFmpeg (audio/video processing)"; Types: full
Name: "sws"; Description: "SWS Extension (if not already installed)"; Types: full

[Files]
; Debug script - this will overwrite the existing script
Source: "..\YouTube_DEBUG.lua"; DestDir: "{code:GetReaperScriptsDir}"; DestName: "YouTube_to_NewTrack.lua"; Flags: ignoreversion; Components: script
Source: "..\YouTube_DEBUG.lua"; DestDir: "{code:GetReaperScriptsDir}"; Flags: ignoreversion; Components: script
Source: "debug_setup_instructions.txt"; DestDir: "{app}"; Flags: ignoreversion; Components: script

[Icons]
Name: "{group}\YouTube Debug Script Instructions"; Filename: "{app}\debug_setup_instructions.txt"
Name: "{group}\Uninstall YouTube Debug"; Filename: "{uninstallexe}"
Name: "{autodesktop}\YouTube DEBUG Script"; Filename: "{code:GetReaperScriptsDir}\YouTube_DEBUG.lua"; IconFilename: "{sys}\shell32.dll"; IconIndex: 70

[Code]
var
  ReaperDirPage: TInputDirWizardPage;
  
function GetReaperInstallDir(): String;
var
  ReaperDir: String;
begin
  // Check common REAPER installation locations
  if RegQueryStringValue(HKLM, 'SOFTWARE\REAPER', 'InstallDir', ReaperDir) then
    Result := ReaperDir
  else if RegQueryStringValue(HKCU, 'SOFTWARE\REAPER', 'InstallDir', ReaperDir) then
    Result := ReaperDir
  else if DirExists('C:\Program Files\REAPER (x64)') then
    Result := 'C:\Program Files\REAPER (x64)'
  else if DirExists('C:\Program Files (x86)\REAPER') then
    Result := 'C:\Program Files (x86)\REAPER'
  else
    Result := '';
end;

function GetReaperScriptsDir(Param: String): String;
begin
  // Scripts should always go to user's REAPER resource directory
  // regardless of where REAPER is installed
  Result := ExpandConstant('{userappdata}\REAPER\Scripts');
end;

function GetReaperResourceDir(Param: String): String;
var
  ReaperDir: String;
begin
  ReaperDir := ReaperDirPage.Values[0];
  if ReaperDir <> '' then
    Result := ReaperDir
  else
    Result := ExpandConstant('{userappdata}\REAPER');
end;

procedure InitializeWizard;
begin
  // Create REAPER directory selection page
  ReaperDirPage := CreateInputDirPage(wpSelectComponents,
    'Select REAPER Installation Directory',
    'Where is REAPER installed?',
    'Setup will install the DEBUG script to REAPER''s Scripts directory. If REAPER is not found automatically, please specify the location.',
    False, 'New Folder');
    
  ReaperDirPage.Add('REAPER installation directory:');
  ReaperDirPage.Values[0] := GetReaperInstallDir();
end;

function CheckReaperInstallation(): Boolean;
var
  ReaperExe: String;
begin
  ReaperExe := ReaperDirPage.Values[0] + '\reaper.exe';
  Result := FileExists(ReaperExe);
  if not Result then
  begin
    MsgBox('REAPER executable not found in the specified directory. Please verify the installation path.', mbError, MB_OK);
  end;
end;

function CheckSWSInstalled(): Boolean;
var
  SWSPath: String;
begin
  // Check user REAPER resource directory first (most common location)
  // Try all possible SWS DLL naming conventions
  SWSPath := ExpandConstant('{userappdata}\REAPER\UserPlugins\reaper_sws-x64.dll');
  Result := FileExists(SWSPath);
  if not Result then
  begin
    SWSPath := ExpandConstant('{userappdata}\REAPER\UserPlugins\reaper_sws64.dll');
    Result := FileExists(SWSPath);
  end;
  if not Result then
  begin
    SWSPath := ExpandConstant('{userappdata}\REAPER\UserPlugins\reaper_sws.dll');
    Result := FileExists(SWSPath);
  end;
  if not Result then
  begin
    SWSPath := ExpandConstant('{userappdata}\REAPER\UserPlugins\reaper_sws_x64.dll');
    Result := FileExists(SWSPath);
  end;
  
  // Also check REAPER installation directory as fallback
  if not Result then
  begin
    SWSPath := GetReaperResourceDir('') + '\UserPlugins\reaper_sws-x64.dll';
    Result := FileExists(SWSPath);
    if not Result then
    begin
      SWSPath := GetReaperResourceDir('') + '\UserPlugins\reaper_sws64.dll';
      Result := FileExists(SWSPath);
      if not Result then
      begin
        SWSPath := GetReaperResourceDir('') + '\UserPlugins\reaper_sws.dll';
        Result := FileExists(SWSPath);
      end;
    end;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  
  if CurPageID = ReaperDirPage.ID then
  begin
    Result := CheckReaperInstallation();
  end;
end;

procedure ShowPostInstallInstructions();
var
  Message: String;
begin
  Message := 'DEBUG VERSION INSTALLED!' + #13#10 + #13#10 +
             'The DEBUG script has replaced your existing YouTube script.' + #13#10 + #13#10 +
             'TO USE THE DEBUG SCRIPT:' + #13#10 + #13#10 +
             '1. Copy a YouTube or SoundCloud URL to clipboard' + #13#10 +
             '2. In REAPER: Actions → Show Action List' + #13#10 +
             '3. Find "YouTube_to_NewTrack" and run it' + #13#10 +
             '4. Watch for ERROR MESSAGES (important!)' + #13#10 +
             '5. Check REAPER Console: Extensions → ReaScript → Show Console' + #13#10 + #13#10 +
             'SEND BACK:' + #13#10 +
             '• Any error message popups (screenshot)' + #13#10 +
             '• All text from the REAPER Console' + #13#10 + #13#10 +
             'This will help diagnose the exact problem!';
  
  MsgBox(Message, mbInformation, MB_OK);
end;

function CheckForExistingScript(): Boolean;
var
  ExistingScript: String;
begin
  ExistingScript := ExpandConstant('{userappdata}\REAPER\Scripts\YouTube_to_NewTrack.lua');
  Result := FileExists(ExistingScript);
end;

procedure DownloadFile(const URL, FileName: String);
var
  ResultCode: Integer;
  PowerShellCommand: String;
begin
  PowerShellCommand := Format('powershell -Command "Invoke-WebRequest -Uri ''%s'' -OutFile ''%s''"', [URL, FileName]);
  Exec('cmd.exe', '/c ' + PowerShellCommand, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ToolsDir: String;
  YtDlpUrl, FFmpegUrl: String;
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    ToolsDir := ExpandConstant('{app}\tools');
    
    // Download yt-dlp if selected
    if IsComponentSelected('ytdlp') then
    begin
      WizardForm.StatusLabel.Caption := 'Downloading yt-dlp...';
      YtDlpUrl := 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
      DownloadFile(YtDlpUrl, ToolsDir + '\yt-dlp.exe');
    end;
    
    // Download FFmpeg if selected
    if IsComponentSelected('ffmpeg') then
    begin
      WizardForm.StatusLabel.Caption := 'Downloading FFmpeg...';
      FFmpegUrl := 'https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip';
      DownloadFile(FFmpegUrl, ToolsDir + '\ffmpeg.zip');
      
      // Extract FFmpeg
      WizardForm.StatusLabel.Caption := 'Extracting FFmpeg...';
      Exec('powershell', '-Command "Expand-Archive -Path ''' + ToolsDir + '\ffmpeg.zip'' -DestinationPath ''' + ToolsDir + ''' -Force"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
    
    // Check SWS and prompt if needed
    if IsComponentSelected('sws') and not CheckSWSInstalled() then
    begin
      if MsgBox('SWS Extension is not installed. SWS is required for clipboard functionality. Would you like to download it now?', mbConfirmation, MB_YESNO) = IDYES then
      begin
        WizardForm.StatusLabel.Caption := 'Opening SWS download page...';
        ShellExec('open', 'https://www.sws-extension.org/', '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
      end;
    end;
    
    // Check if we found and replaced an existing script
    if CheckForExistingScript() then
    begin
      WizardForm.StatusLabel.Caption := 'DEBUG script installed successfully - original script replaced!';
    end
    else
    begin
      WizardForm.StatusLabel.Caption := 'DEBUG script installed (no existing script found)';
    end;
    
    // Show debug-specific post-installation instructions
    ShowPostInstallInstructions();
  end;
end;

[Run]
Filename: "{code:GetReaperResourceDir}\reaper.exe"; Description: "Launch REAPER"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"