@echo off
setlocal enabledelayedexpansion

:: CI/CD configuration
if "%CI%"=="true" (
    set LOG_LEVEL=debug
) else (
    set LOG_LEVEL=info
)

:: Get config values
for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File get-config.ps1 -Key steam_path') do set STEAM_PATH=%%i
for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File get-config.ps1 -Key rust_path') do set RUST_PATH=%%i
for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File get-config.ps1 -Key rust_app_id') do set RUST_APP_ID=%%i

:: Logging function
:log
echo [%date% %time%] [%LOG_LEVEL%] %~1
goto :eof

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    call :log "Script must be run as Administrator"
    exit /b 1
)

:: Check Steam installation
if not exist "%STEAM_PATH%\Steam.exe" (
    call :log "Steam not found. Please run install-steam-rust.nu first"
    exit /b 1
)

:: Check Rust installation
if not exist "%RUST_PATH%" (
    call :log "Rust not found. Please run install-steam-rust.nu first"
    exit /b 1
)

:: Launch Steam
call :log "Launching Steam..."
start "" "%STEAM_PATH%\Steam.exe" -silent

:: Wait for Steam to start
timeout /t 10 /nobreak >nul

:: Launch Rust
call :log "Launching Rust..."
start "" "%STEAM_PATH%\Steam.exe" -applaunch %RUST_APP_ID%

:: Monitor process
:monitor
tasklist /FI "IMAGENAME eq RustClient.exe" 2>NUL | find /I /N "RustClient.exe">NUL
if "%ERRORLEVEL%"=="0" (
    timeout /t 5 /nobreak >nul
    goto monitor
) else (
    call :log "Rust has been closed"
    exit /b 0
)

endlocal 