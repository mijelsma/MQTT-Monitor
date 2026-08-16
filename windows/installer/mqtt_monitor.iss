#define AppName "MQTT Monitor"
#define AppExecutable "mqtt_monitor.exe"
#define AppPublisher "Michel Jelsma"
#define AppVersion GetEnv("MQTT_MONITOR_RELEASE_VERSION")
#define InstallerFileVersion GetEnv("MQTT_MONITOR_INSTALLER_FILE_VERSION")
#define ProjectRoot GetEnv("MQTT_MONITOR_PROJECT_ROOT")
#define VcRedistX64 GetEnv("VC_REDIST_X64")

[Setup]
AppId={{E733335C-5020-45E9-A145-935CDC3FF42A}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://github.com/mijelsma/MQTT-Monitor
AppSupportURL=https://github.com/mijelsma/MQTT-Monitor/issues
AppUpdatesURL=https://github.com/mijelsma/MQTT-Monitor/releases
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir={#SourcePath}
OutputBaseFilename=MQTT-Monitor-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
SetupIconFile={#ProjectRoot}\windows\runner\resources\app_icon.ico
LicenseFile={#ProjectRoot}\LICENSE
UninstallDisplayIcon={app}\{#AppExecutable}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} Installer
VersionInfoVersion={#InstallerFileVersion}

[Files]
Source: "{#ProjectRoot}\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#VcRedistX64}"; DestDir: "{tmp}"; DestName: "vc_redist.x64.exe"; Flags: deleteafterinstall

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExecutable}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExecutable}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ Runtime..."; Flags: waituntilterminated; Check: VcRedistNeedsInstall
Filename: "{app}\{#AppExecutable}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Code]
function VcRedistNeedsInstall: Boolean;
var
  Installed: Cardinal;
begin
  Result :=
    (not RegQueryDWordValue(
      HKLM64,
      'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
      'Installed',
      Installed)) or
    (Installed <> 1);
end;
