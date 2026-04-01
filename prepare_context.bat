@echo off
setlocal enabledelayedexpansion
:: ============================================================================
:: prepare_context.bat
:: Cleans up the householdchores project and creates a minimal-context zip
:: for sharing with an AI assistant in a new chat session.
::
:: Run from the project root (where this file lives).
::
:: What it removes before zipping:
::   - frontend\.dart_tool\          (generated, contains Windows-absolute paths)
::   - frontend\build\               (compiled output)
::   - frontend\.flutter-plugins*    (generated)
::   - frontend\android\.gradle\     (Gradle cache)
::   - backend\pb_data\storage\      (user-uploaded files / binary test data)
::   - backend\pb_data\*.db          (live SQLite databases)
::   - .git\                         (version control history)
::   - .claude\                      (Claude Code config)
::   - frontend\.idea\               (IDE workspace state)
::   - plans\                        (internal planning notes)
::
:: Output: householdchores_context.zip next to this script.
:: ============================================================================

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

echo.
echo ============================================================
echo  Household Chores -- context zip builder
echo  Project root: %ROOT%
echo ============================================================
echo.

:: ----------------------------------------------------------------------------
:: 1. Remove generated and binary artefacts
:: ----------------------------------------------------------------------------
echo [1/3] Removing generated and build artefacts...

set DIRS_TO_DELETE=^
  frontend\.dart_tool ^
  frontend\build ^
  frontend\.pub-cache ^
  frontend\android\.gradle ^
  frontend\android\app\.cxx ^
  backend\pb_data\storage ^
  plans ^
  .claude ^
  frontend\.idea

for %%D in (%DIRS_TO_DELETE%) do (
  if exist "%ROOT%\%%D" (
    echo   Deleting %%D
    rd /s /q "%ROOT%\%%D" 2>nul
  )
)

for %%F in (
  "frontend\.flutter-plugins"
  "frontend\.flutter-plugins-dependencies"
  "frontend\.packages"
) do (
  if exist "%ROOT%\%%~F" (
    echo   Deleting %%~F
    del /f /q "%ROOT%\%%~F" 2>nul
  )
)

if exist "%ROOT%\backend\pb_data\data.db" (
  echo   Deleting backend\pb_data\data.db
  del /f /q "%ROOT%\backend\pb_data\data.db" 2>nul
)
if exist "%ROOT%\backend\pb_data\auxiliary.db" (
  echo   Deleting backend\pb_data\auxiliary.db
  del /f /q "%ROOT%\backend\pb_data\auxiliary.db" 2>nul
)

echo   Done.
echo.

:: ----------------------------------------------------------------------------
:: 2. Print full directory overview
:: ----------------------------------------------------------------------------
echo [2/3] Directory overview (all remaining files):
echo ============================================================
pushd "%ROOT%"
for /f "delims=" %%F in ('dir /s /b /a:-d 2^>nul ^| findstr /v /i "\\\.git\\"') do (
  set "FPATH=%%F"
  set "FPATH=!FPATH:%ROOT%\=!"
  echo   !FPATH!
)
popd
echo ============================================================
echo.
echo  Key source files for AI context:
echo.
echo  ROOT
echo    docker-compose.yaml              -- orchestrates all services (run from here)
echo    Dockerfile.web                   -- multi-stage Flutter web + nginx build
echo    .dockerignore                    -- excludes Windows paths from Docker context
echo    VERSION                          -- single version source of truth
echo    release.ps1                      -- version bump + APK build + git tag + push
echo    prepare_context.bat              -- this script
echo.
echo  BACKEND
echo    backend\Dockerfile               -- PocketBase container
echo    backend\nginx.conf               -- nginx config (baked into web image)
echo    backend\.env.example             -- env var reference
echo    backend\pb_hooks\*.pb.js         -- HA webhook + version endpoint
echo    backend\pb_migrations\*.js       -- DB schema history (auto-applied on start)
echo.
echo  FRONTEND (Flutter/Dart)
echo    frontend\lib\main.dart           -- app entry + providers
echo    frontend\lib\config\app_config.dart  -- version + dynamic backend URL
echo    frontend\lib\models\*.dart       -- data models
echo    frontend\lib\providers\*.dart    -- state management
echo    frontend\lib\services\*.dart     -- API, auth, version check, connection
echo    frontend\lib\screens\**\*.dart   -- UI screens (dashboard, login, admin...)
echo    frontend\lib\l10n\*.arb          -- translations (EN/NL/ES)
echo    frontend\pubspec.yaml            -- dependencies + app version
echo.
echo  DOCS
echo    AI_CONTEXT.md                    -- architecture, gotchas, conventions
echo    README.md                        -- setup, APK distribution, Docker usage
echo.

:: ----------------------------------------------------------------------------
:: 3. Create zip
:: ----------------------------------------------------------------------------
echo [3/3] Creating zip archive...

set "ZIPFILE=%ROOT%\householdchores_context.zip"
if exist "%ZIPFILE%" del /f /q "%ZIPFILE%"

powershell -NoProfile -Command ^
  "Compress-Archive -Path '%ROOT%\*' -DestinationPath '%ZIPFILE%' -CompressionLevel Optimal"

if errorlevel 1 (
  echo.
  echo   ERROR: zip creation failed. Make sure PowerShell is available.
  exit /b 1
)

for %%Z in ("%ZIPFILE%") do set "ZIPSIZE=%%~zZ"
set /a "ZIPSIZE_KB=%ZIPSIZE% / 1024"
set /a "ZIPSIZE_MB=%ZIPSIZE_KB% / 1024"

echo.
echo ============================================================
echo  Done!
echo  Output : %ZIPFILE%
echo  Size   : %ZIPSIZE_MB% MB  (%ZIPSIZE_KB% KB)
echo ============================================================
echo.
echo  TIP: Upload householdchores_context.zip to your next chat.
echo  Always share AI_CONTEXT.md first -- the AI should read it
echo  before making any changes.
echo.
endlocal