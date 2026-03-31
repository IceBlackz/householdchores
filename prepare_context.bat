@echo off
setlocal enabledelayedexpansion
:: ============================================================================
:: prepare_context.bat
:: Cleans up the householdchores project and creates a minimal-context zip for
:: sharing with an AI assistant in a new chat session.
::
:: Usage: run from the project root (where this file lives), or from anywhere —
::        the script locates itself automatically.
::
:: What it removes before zipping:
::   - frontend\.dart_tool\          (generated, large)
::   - frontend\build\               (compiled output)
::   - frontend\.flutter-plugins*    (generated)
::   - frontend\.pub-cache\          (local pub cache, if present)
::   - frontend\android\.gradle\     (Gradle cache)
::   - frontend\android\app\.cxx\    (CMake intermediate)
::   - backend\pb_data\storage\      (user-uploaded files / test data)
::   - backend\pb_data\*.db          (live database — not useful for AI)
::   - plans\                        (internal planning notes)
::   - .git\                         (version control history)
::   - .claude\                      (Claude Code config)
::   - .idea\                        (IDE workspace state)
::
:: Output: householdchores_context.zip next to this script.
:: ============================================================================

:: Resolve project root (directory containing this script)
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

echo.
echo ============================================================
echo  Household Chores — context zip builder
echo  Project root: %ROOT%
echo ============================================================
echo.

:: ----------------------------------------------------------------------------
:: 1. Clean generated / build artefacts inside the project folder
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

:: Remove generated single-file artefacts
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

:: Remove PocketBase live databases (binary, not useful for AI)
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
:: 2. Print a full directory overview so the AI knows what files exist
:: ----------------------------------------------------------------------------
echo [2/3] Directory overview (all remaining files):
echo ============================================================
pushd "%ROOT%"
for /f "delims=" %%F in ('dir /s /b /a:-d 2^>nul ^| findstr /v /i "\\\.git\\"') do (
  set "FPATH=%%F"
  :: Strip the root prefix so paths are relative
  set "FPATH=!FPATH:%ROOT%\=!"
  echo   !FPATH!
)
popd
echo ============================================================
echo.
echo  Key source files for AI context:
echo.
echo  BACKEND
echo    backend\pb_hooks\notify_homeassistant.pb.js   — HA webhook hook
echo    backend\pb_migrations\*.js                    — DB schema history
echo    backend\pb_data\types.d.ts                    — PocketBase type defs
echo    backend\.env.example                          — env var reference
echo    backend\Dockerfile + docker-compose.yaml      — container setup
echo.
echo  FRONTEND (Flutter/Dart)
echo    frontend\lib\main.dart                        — app entry + providers
echo    frontend\lib\models\*.dart                    — data models
echo    frontend\lib\providers\*.dart                 — state management
echo    frontend\lib\services\*.dart                  — API + connection logic
echo    frontend\lib\screens\**\*.dart                — UI screens
echo    frontend\lib\constants\app_constants.dart     — shared constants
echo    frontend\lib\config\app_config.dart           — backend URL config
echo    frontend\lib\l10n\*.arb                       — translations (EN/NL/ES)
echo    frontend\pubspec.yaml                         — dependencies
echo    frontend\analysis_options.yaml                — linting rules
echo    frontend\test\models\chore_test.dart          — unit tests
echo.
echo  DOCS
echo    AI_CONTEXT.md                                 — project overview doc
echo    README.md                                     — general readme
echo    plans\fix_errors_plan.md                      — (removed in cleanup)
echo.

:: ----------------------------------------------------------------------------
:: 3. Create the zip
:: ----------------------------------------------------------------------------
echo [3/3] Creating zip archive...

set "ZIPFILE=%ROOT%\householdchores_context.zip"
if exist "%ZIPFILE%" del /f /q "%ZIPFILE%"

:: Use PowerShell's Compress-Archive (available on Windows 10+)
powershell -NoProfile -Command ^
  "Compress-Archive -Path '%ROOT%\*' -DestinationPath '%ZIPFILE%' -CompressionLevel Optimal"

if errorlevel 1 (
  echo.
  echo   ERROR: zip creation failed. Make sure PowerShell is available.
  exit /b 1
)

:: Report size
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
echo  The AI will have all source files without any generated
echo  or binary bloat.
echo.
endlocal
