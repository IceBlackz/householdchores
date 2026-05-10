# Household Chores release script
# Usage: .\release.ps1 -Version 1.2.0
# Requires: Flutter in PATH, git in PATH, gh (GitHub CLI) for release upload (optional)
param(
  [Parameter(Mandatory)][string]$Version
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = $PSScriptRoot
$Frontend = Join-Path $Root "frontend"
$Backend = Join-Path $Root "backend"

# ---------- 1. Validate version format ----------
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
  Write-Error "Version must be MAJOR.MINOR.PATCH (e.g. 1.2.0)"
  exit 1
}

Write-Host ""
Write-Host "=========================================="
Write-Host " Releasing Household Chores v$Version"
Write-Host "=========================================="
Write-Host ""

$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne 'y') {
  Write-Host "Aborted."
  exit 0
}

# ---------- 2. Update VERSION file ----------
Write-Host "[1/6] Updating VERSION file..."
Set-Content (Join-Path $Root "VERSION") $Version -NoNewline

# ---------- 3. Update pubspec.yaml ----------
Write-Host "[2/6] Updating frontend/pubspec.yaml..."
$pubspecPath = Join-Path $Frontend "pubspec.yaml"
$pubspec = Get-Content $pubspecPath -Raw
if ($pubspec -match 'version:\s*\d+\.\d+\.\d+\+(\d+)') {
  $buildNum = [int]$Matches[1] + 1
} else {
  $buildNum = 1
}
$pubspec = $pubspec -replace 'version:\s*[\d.]+\+\d+', "version: $Version+$buildNum"
Set-Content $pubspecPath $pubspec -NoNewline

# ---------- 4. Update app_config.dart ----------
Write-Host "[3/6] Updating AppConfig.appVersion..."
$configPath = Join-Path $Frontend "lib\config\app_config.dart"
$config = Get-Content $configPath -Raw
$config = $config -replace "appVersion = '[^']*'", "appVersion = '$Version'"
Set-Content $configPath $config -NoNewline

# ---------- 5. Update pb_hooks/version.pb.js ----------
Write-Host "[4/6] Updating server version hook..."
$hookPath = Join-Path $Backend "pb_hooks\version.pb.js"
$hook = Get-Content $hookPath -Raw
$hook = $hook -replace 'version: "[^"]*"', "version: `"$Version`""
$hook = $hook -replace 'minAppVersion: "[^"]*"', "minAppVersion: `"$Version`""
Set-Content $hookPath $hook -NoNewline

# ---------- 6. Build APK ----------
Write-Host "[5/6] Building Android APK..."
Push-Location $Frontend
flutter pub get
flutter gen-l10n
flutter build apk --release
Pop-Location

$ApkSrc = Join-Path $Frontend "build\app\outputs\flutter-apk\app-release.apk"
$ApkDest = Join-Path $Root "householdchores-v$Version.apk"
Copy-Item $ApkSrc $ApkDest
Write-Host "  APK: $ApkDest"

$DownloadDir = Join-Path $Frontend "web\downloads"
New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null
$ServerApkDest = Join-Path $DownloadDir "householdchores-latest.apk"
Copy-Item $ApkSrc $ServerApkDest
Write-Host "  Server download APK: frontend\web\downloads\householdchores-latest.apk"

# ---------- 7. Commit, tag, push ----------
# The web app is built inside Docker. The generated latest APK is ignored by git
# but copied into frontend/web/downloads for local server deployments.
Write-Host "[6/6] Committing and tagging..."
Push-Location $Root
git add -A
git commit -m "Release v$Version

- Bump version to $Version (build $buildNum)
- Web app built automatically by Docker on next deploy
- Android APK copied to frontend/web/downloads for server installs
- Updated server version hook"
git tag -a "v$Version" -m "Release v$Version"
git push
git push --tags
Pop-Location

# ---------- Optional: GitHub release ----------
if (Get-Command gh -ErrorAction SilentlyContinue) {
  Write-Host ""
  $createRelease = Read-Host "Create GitHub release? (y/N)"
  if ($createRelease -eq 'y') {
    gh release create "v$Version" $ApkDest `
      --title "v$Version" `
      --notes "## Household Chores v$Version

### Install on Android
Download ``householdchores-v$Version.apk`` from this release or use your server install page after deployment:

````text
http://your-server:9011/install.html
````

Android may ask you to allow installs from your browser.

### Deploy / update server
````powershell
git pull
docker compose up -d --build
````

The web app on port 9011 is rebuilt automatically."
    Write-Host "  GitHub release created."
  }
} else {
  Write-Host ""
  Write-Host "  (Install 'gh' CLI to auto-create GitHub releases)"
}

Write-Host ""
Write-Host "=========================================="
Write-Host " Done! v$Version released."
Write-Host " APK: householdchores-v$Version.apk"
Write-Host " Server APK path: frontend\web\downloads\householdchores-latest.apk"
Write-Host " Web: rebuilt by Docker on next deploy"
Write-Host "=========================================="
Write-Host ""
Write-Host " To deploy the update:"
Write-Host "   docker compose up -d --build"
Write-Host ""
