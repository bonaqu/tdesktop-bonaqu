#define MyAppShortName "Bonaqu Client"
#define MyAppName "Bonaqu Client"
#define MyAppPublisher "bonaqu"
#define MyAppURL "https://github.com/bonaqu/tdesktop-bonaqu"
#define MyAppExeName "BonaquClient.exe"
#define MyAppId "D4195297-1CA0-47BB-9EB9-8239E93692A9"
#define CurrentYear GetDateTimeString('yyyy','','')

[Setup]
; Bonaqu Client intentionally uses its own AppId so Windows treats it as a
; separate application from official Telegram Desktop.
AppId={{{#MyAppId}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppCopyright=Derived from Telegram Desktop (C) 2014-{#CurrentYear}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={userappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir={#ReleasePath}
SetupIconFile={#SourcePath}..\Resources\art\icon256.ico
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
DisableStartupPrompt=yes
PrivilegesRequired=lowest
VersionInfoVersion={#MyAppVersion}.0
CloseApplications=force
DisableDirPage=no
DisableProgramGroupPage=no
WizardStyle=modern
SignTool=sha256

#if MyBuildTarget == "winarm"
  ArchitecturesAllowed="arm64"
  OutputBaseFilename=bonaqu-client-setup-arm64.{#MyAppVersionFull}
  #define ArchModulesFolder "arm64"
  AppVerName={#MyAppName} {#MyAppVersion} arm64
#elif MyBuildTarget == "win64"
  ArchitecturesAllowed="x64compatible"
  ArchitecturesInstallIn64BitMode="x64compatible"
  OutputBaseFilename=bonaqu-client-setup-x64.{#MyAppVersionFull}
  #define ArchModulesFolder "x64"
  AppVerName={#MyAppName} {#MyAppVersion} 64bit
#else
  OutputBaseFilename=bonaqu-client-setup.{#MyAppVersionFull}
  #define ArchModulesFolder "x86"
  AppVerName={#MyAppName} {#MyAppVersion} 32bit
#endif

#define ModulesFolder "modules\" + ArchModulesFolder

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "it";      MessagesFile: "compiler:Languages\Italian.isl"
Name: "es";      MessagesFile: "compiler:Languages\Spanish.isl"
Name: "de";      MessagesFile: "compiler:Languages\German.isl"
Name: "nl";      MessagesFile: "compiler:Languages\Dutch.isl"
Name: "pt_BR";   MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "ru";      MessagesFile: "compiler:Languages\Russian.isl"
Name: "fr";      MessagesFile: "compiler:Languages\French.isl"
Name: "ua";      MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Upstream target is still built as Telegram.exe; the installer gives the fork
; its own filename on disk without changing the upstream CMake target name.
Source: "{#ReleasePath}\Telegram.exe"; DestDir: "{app}"; DestName: "BonaquClient.exe"; Flags: ignoreversion
#if MyBuildTarget != "winarm"
Source: "{#ReleasePath}\{#ModulesFolder}\d3d\d3dcompiler_47.dll"; DestDir: "{app}\{#ModulesFolder}\d3d"; Flags: ignoreversion
#endif
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppShortName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppShortName}}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#MyAppShortName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppShortName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\data"
Type: files; Name: "{app}\data_config"
Type: files; Name: "{app}\log.txt"
Type: filesandordirs; Name: "{app}\DebugLogs"
Type: filesandordirs; Name: "{app}\tupdates"
Type: filesandordirs; Name: "{app}\tdata"
Type: filesandordirs; Name: "{app}\tcache"
Type: filesandordirs; Name: "{app}\tdumps"
Type: filesandordirs; Name: "{app}\modules"
Type: dirifempty; Name: "{app}"
Type: files; Name: "{userappdata}\{#MyAppName}\data"
Type: files; Name: "{userappdata}\{#MyAppName}\data_config"
Type: files; Name: "{userappdata}\{#MyAppName}\log.txt"
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}\DebugLogs"
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}\tupdates"
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}\tdata"
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}\tcache"
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}\tdumps"
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}\modules"
Type: dirifempty; Name: "{userappdata}\{#MyAppName}"

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    Exec(ExpandConstant('{app}\{#MyAppExeName}'), '-cleanup', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

const CSIDL_DESKTOPDIRECTORY = $0010;
      CSIDL_COMMON_DESKTOPDIRECTORY = $0019;

procedure CurStepChanged(CurStep: TSetupStep);
var ResultCode: Integer;
    HasOldKey: Boolean;
    HasNewKey: Boolean;
    HasOldLnk: Boolean;
    HasNewLnk: Boolean;
    UserDesktopLnk: String;
    CommonDesktopLnk: String;
begin
  if CurStep = ssPostInstall then
  begin
    HasNewKey := RegKeyExists(HKEY_CURRENT_USER, 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{{#MyAppId}}_is1') or RegKeyExists(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{{#MyAppId}}_is1');
    HasOldKey := RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{{#MyAppId}}_is1') or RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{{#MyAppId}}_is1');
    UserDesktopLnk := ExpandFileName(GetShellFolderByCSIDL(CSIDL_DESKTOPDIRECTORY, False) + '\{#MyAppShortName}.lnk');
    CommonDesktopLnk := ExpandFileName(GetShellFolderByCSIDL(CSIDL_COMMON_DESKTOPDIRECTORY, False) + '\{#MyAppShortName}.lnk');
    HasNewLnk := FileExists(UserDesktopLnk);
    HasOldLnk := FileExists(CommonDesktopLnk) and (UserDesktopLnk <> CommonDesktopLnk);
    if (HasOldKey and HasNewKey) or (HasOldLnk and HasNewLnk) then
    begin
      if (GetWindowsVersion >= $06000000) then // Vista or later
        ShellExec('runas', ExpandConstant('{app}\{#MyAppExeName}'), '-fixprevious', '', SW_SHOW, ewWaitUntilTerminated, ResultCode)
      else
        ShellExec('', ExpandConstant('{app}\{#MyAppExeName}'), '-fixprevious', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;
