#define AppName "MISSION SAUVETAGE LIVE"
#define AppVersion "0.4.0"
[Setup]
AppId={{EF938D1F-02A3-4EB2-9FA8-11204F8AA7CC}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\MISSION SAUVETAGE LIVE
DefaultGroupName=MISSION SAUVETAGE LIVE
PrivilegesRequired=lowest
OutputDir=..\..\release-rescue
OutputBaseFilename=MISSION-SAUVETAGE-LIVE-Setup-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
UninstallDisplayName=MISSION SAUVETAGE LIVE

[Files]
Source: "..\..\dist-rescue\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
[Icons]
Name: "{group}\MISSION SAUVETAGE LIVE"; Filename: "{app}\DEMARRER-MISSION-SAUVETAGE.cmd"
Name: "{autodesktop}\MISSION SAUVETAGE LIVE"; Filename: "{app}\DEMARRER-MISSION-SAUVETAGE.cmd"
[Run]
Filename: "{app}\DEMARRER-MISSION-SAUVETAGE.cmd"; Description: "Lancer MISSION SAUVETAGE LIVE"; Flags: nowait postinstall skipifsilent
