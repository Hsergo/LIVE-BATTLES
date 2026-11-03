#define AppName "LIVE BATTLES"
#define AppVersion "0.1.0"

[Setup]
AppId={{5D82B353-327C-4D50-ABA6-63B5C7824D27}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\LIVE BATTLES
DefaultGroupName=LIVE BATTLES
PrivilegesRequired=lowest
OutputDir=..\release
OutputBaseFilename=LIVE-BATTLE-Setup-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible

[Files]
Source: "..\dist\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\LIVE BATTLES"; Filename: "{app}\DEMARRER-LIVE-BATTLE.cmd"
Name: "{autodesktop}\LIVE BATTLES"; Filename: "{app}\DEMARRER-LIVE-BATTLE.cmd"

[Run]
Filename: "{app}\DEMARRER-LIVE-BATTLE.cmd"; Description: "Lancer LIVE BATTLES"; Flags: nowait postinstall skipifsilent
