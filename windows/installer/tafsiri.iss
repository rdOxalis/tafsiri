; Tafsiri — Inno Setup installer script (ADR-035).
;
; Builds a single tafsiri-<version>-windows-x64.exe from the Flutter release bundle.
; Do not compile this by hand: build_windows.ps1 builds the app first and passes
; the version from pubspec.yaml in via /DAppVersion.
;
;   iscc /DAppVersion=1.0.10 windows\installer\tafsiri.iss
;
; The install is per user (PrivilegesRequired=lowest), so it needs no admin
; rights and lands in %LOCALAPPDATA%\Programs\Tafsiri.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef BuildDir
  #define BuildDir "..\..\build\windows\x64\runner\Release"
#endif

#define AppName "Tafsiri"
#define AppPublisher "ke.darkman"
#define AppUrl "https://github.com/ooocp/tafsiri"
#define AppExe "tafsiri.exe"

; Settings and translation history live here (path_provider's application
; support directory, derived from CompanyName/ProductName in Runner.rc).
#define UserDataDir "{userappdata}\ke.darkman\Tafsiri"

[Setup]
; Never change AppId — it is what ties an upgrade to an existing installation.
AppId={{7B5EFDA8-40B6-454C-A224-9E1BE70465FD}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
AppUpdatesURL={#AppUrl}/releases
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\build\windows\installer
; Matches the naming of the other release assets: tafsiri-<version>[-platform].
OutputBaseFilename=tafsiri-{#AppVersion}-windows-x64
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; A running Tafsiri holds tafsiri.exe open; offer to close it instead of
; forcing a reboot.
CloseApplications=yes
RestartApplications=no

[Languages]
; Only the locales Inno Setup ships out of the box. Tafsiri's Swahili and
; Swedish UI translations have no counterpart here, so those users get the
; English installer and a translated app.
;
; If ISCC ever fails with "Could not open file ...\<Language>.isl", that
; translation is not in the installed Inno Setup — drop the line rather than
; hunting for the file.
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "da"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "no"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "pl"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "bg"; MessagesFile: "compiler:Languages\Bulgarian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[CustomMessages]
en.KeepDataPrompt=Keep your Tafsiri settings, API keys and translation history?%n%nChoose Yes to keep them for a later reinstall, or No to delete them permanently.
de.KeepDataPrompt=Einstellungen, API-Schlüssel und Übersetzungsverlauf von Tafsiri behalten?%n%nJa behält alles für eine spätere Neuinstallation, Nein löscht die Daten endgültig.
fr.KeepDataPrompt=Conserver vos paramètres, clés d'API et historique de traduction Tafsiri ?%n%nOui les conserve pour une réinstallation ultérieure, Non les supprime définitivement.
nl.KeepDataPrompt=Je Tafsiri-instellingen, API-sleutels en vertaalgeschiedenis behouden?%n%nJa bewaart alles voor een latere herinstallatie, Nee verwijdert ze definitief.
es.KeepDataPrompt=¿Conservar la configuración, las claves de API y el historial de traducciones de Tafsiri?%n%nSí las conserva para una reinstalación posterior, No las elimina definitivamente.
da.KeepDataPrompt=Vil du beholde dine Tafsiri-indstillinger, API-nøgler og oversættelseshistorik?%n%nJa beholder dem til en senere geninstallation, Nej sletter dem permanent.
no.KeepDataPrompt=Vil du beholde Tafsiri-innstillingene, API-nøklene og oversettelsesloggen?%n%nJa beholder dem til en senere reinstallasjon, Nei sletter dem permanent.
pl.KeepDataPrompt=Zachować ustawienia, klucze API i historię tłumaczeń Tafsiri?%n%nTak zachowa je na potrzeby ponownej instalacji, Nie usunie je trwale.
it.KeepDataPrompt=Conservare impostazioni, chiavi API e cronologia delle traduzioni di Tafsiri?%n%nSì le conserva per una futura reinstallazione, No le elimina definitivamente.
bg.KeepDataPrompt=Да се запазят ли настройките, API ключовете и историята на преводите на Tafsiri?%n%nДа ги запазва за бъдещо преинсталиране, Не ги изтрива безвъзвратно.

[Code]
{ Uninstalling must not silently destroy the user's API keys and history — that
  is the very data ADR-034's backup feature exists to protect. Ask, and default
  to keeping it. }
procedure CurUninstallStepChanged(CurStep: TUninstallStep);
var
  DataDir: String;
begin
  { A silent uninstall must not stop on a dialog, and keeping the data is the
    safe answer, so only ask when there is someone to answer. }
  if (CurStep = usPostUninstall) and (not UninstallSilent) then
  begin
    DataDir := ExpandConstant('{#UserDataDir}');
    if DirExists(DataDir) then
      if MsgBox(CustomMessage('KeepDataPrompt'), mbConfirmation, MB_YESNO or MB_DEFBUTTON1) = IDNO then
        DelTree(DataDir, True, True, True);
  end;
end;
