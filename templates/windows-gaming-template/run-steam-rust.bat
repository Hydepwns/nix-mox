@echo off
setlocal enabledelayedexpansion

:: CI/CD configuration
if "%CI%"=="true" (
    set LOG_LEVEL=debug
) else (
    set LOG_LEVEL=info
)

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
if not exist "C:\Program Files (x86)\Steam\Steam.exe" (
    call :log "Steam not found. Please run install-steam-rust.nu first"
    exit /b 1
)

:: Check Rust installation
if not exist "C:\Program Files (x86)\Steam\steamapps\common\Rust" (
    call :log "Rust not found. Please run install-steam-rust.nu first"
    exit /b 1
)

:: Launch Steam
call :log "Launching Steam..."
start "" "C:\Program Files (x86)\Steam\Steam.exe" -silent

:: Wait for Steam to start
timeout /t 10 /nobreak >nul

:: Launch Rust
call :log "Launching Rust..."
start "" "C:\Program Files (x86)\Steam\Steam.exe" -applaunch 252490

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