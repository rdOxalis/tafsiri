#Requires -Version 5.1
<#
.SYNOPSIS
    Tafsiri - build the Windows desktop app and package it as an installer.

.DESCRIPTION
    Builds the Flutter release bundle and compiles windows\installer\tafsiri.iss
    with Inno Setup into build\windows\installer\TafsiriSetup-<version>.exe.

    The installer installs per user (no admin rights, no UAC prompt) into
    %LOCALAPPDATA%\Programs\Tafsiri.

    Requirements:
      - Flutter SDK on PATH, with Windows desktop enabled
      - Visual Studio 2022 with "Desktop development with C++"
      - Inno Setup 6.3+ (winget install JRSoftware.InnoSetup) - only needed for
        the installer step, not for the app itself

.PARAMETER Rebuild
    Delete build\windows first and build from scratch.

.PARAMETER SkipInstaller
    Build the app only; do not compile the installer.

.EXAMPLE
    .\build_windows.ps1
.EXAMPLE
    .\build_windows.ps1 -Rebuild
#>
[CmdletBinding()]
param(
    [switch]$Rebuild,
    [switch]$SkipInstaller
)

$ErrorActionPreference = 'Stop'

$ProjectDir = $PSScriptRoot
$BundleDir  = Join-Path $ProjectDir 'build\windows\x64\runner\Release'
$OutputDir  = Join-Path $ProjectDir 'build\windows\installer'
$IssFile    = Join-Path $ProjectDir 'windows\installer\tafsiri.iss'

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Note {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor DarkGray
}

function Fail {
    param([string]$Message)
    Write-Host " error: $Message" -ForegroundColor Red
    exit 1
}

# ----------------------------------------------------------------- version --

function Get-PubspecVersion {
    # "version: 1.0.10+10" -> "1.0.10". Inno's VersionInfoVersion rejects the
    # build-number suffix, and it means nothing on Windows anyway.
    $line = Select-String -Path (Join-Path $ProjectDir 'pubspec.yaml') `
                          -Pattern '^version:\s*(.+)$' | Select-Object -First 1
    if (-not $line) { Fail 'No version found in pubspec.yaml.' }
    return ($line.Matches[0].Groups[1].Value.Trim() -split '\+')[0]
}

# ------------------------------------------------------------------- build --

function Assert-Flutter {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Fail 'flutter not found on PATH. Install the Flutter SDK first.'
    }
}

function Build-App {
    if ($Rebuild) {
        Write-Step 'Removing build\windows for a clean rebuild...'
        Remove-Item -Recurse -Force (Join-Path $ProjectDir 'build\windows') -ErrorAction SilentlyContinue
    }

    Write-Step 'Fetching packages...'
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { Fail 'flutter pub get failed.' }

    Write-Step 'Building Tafsiri (release)...'
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) { Fail 'flutter build windows failed.' }

    if (-not (Test-Path (Join-Path $BundleDir 'tafsiri.exe'))) {
        Fail "Build finished but $BundleDir\tafsiri.exe is missing."
    }
}

function Assert-BundleComplete {
    # sqlite3.cmake fetches this and CMake installs it next to the exe (ADR-035).
    # Without it the app starts but every history read and every save fails, so
    # catch it here rather than in a user's hands.
    if (-not (Test-Path (Join-Path $BundleDir 'sqlite3.dll'))) {
        Fail @"
sqlite3.dll is missing from the bundle - history and saving translations would
fail at runtime. windows\sqlite3.cmake downloads it during the CMake configure
step; re-run with -Rebuild, and check that this machine can reach sqlite.org.
"@
    }

    # Flutter does not ship the MSVC runtime; windows\CMakeLists.txt copies it
    # from the local Visual Studio install. Only warn - it is missing merely on
    # machines that already have the redistributable installed system-wide.
    if (-not (Test-Path (Join-Path $BundleDir 'msvcp140.dll'))) {
        Write-Host " warning: msvcp140.dll is not in the bundle. The app will run here, but may" -ForegroundColor Yellow
        Write-Host "          not start on machines without the Visual C++ redistributable." -ForegroundColor Yellow
    }
}

# --------------------------------------------------------------- installer --

function Find-InnoSetup {
    $iscc = Get-Command iscc.exe -ErrorAction SilentlyContinue
    if ($iscc) { return $iscc.Source }

    $candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    return $null
}

function Build-Installer {
    param([string]$Version)

    $iscc = Find-InnoSetup
    if (-not $iscc) {
        Write-Host " warning: Inno Setup not found - skipping the installer." -ForegroundColor Yellow
        Write-Note 'Install it with:  winget install JRSoftware.InnoSetup'
        Write-Note "The app itself is ready to run: $BundleDir\tafsiri.exe"
        return $null
    }

    Write-Step "Compiling the installer with $iscc..."
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    & $iscc "/DAppVersion=$Version" $IssFile
    if ($LASTEXITCODE -ne 0) { Fail 'Inno Setup failed to compile the installer.' }

    return (Join-Path $OutputDir "TafsiriSetup-$Version.exe")
}

# -------------------------------------------------------------------- main --

Assert-Flutter
$version = Get-PubspecVersion
Write-Step "Tafsiri $version"

Build-App
Assert-BundleComplete

$installer = $null
if (-not $SkipInstaller) { $installer = Build-Installer -Version $version }

Write-Host ''
Write-Step 'Done.'
Write-Note "App bundle: $BundleDir"
if ($installer -and (Test-Path $installer)) {
    Write-Note "Installer:  $installer"
}
Write-Host ''
Write-Note 'Note: voice input and image OCR are unavailable on Windows - those'
Write-Note 'plugins have no Windows implementation (see docs/decisions.md, ADR-035).'
