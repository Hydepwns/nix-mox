@echo off
REM run-steam-rust.bat
REM Usage: run-steam-rust.bat [--help]
REM
REM Options:
REM   --help            Show this help message
REM
REM Run NuShell script to install Steam and prompt for Rust (Facepunch) installation.
REM Target OS: Windows (Batch)

:log
@REM Usage: call :log LEVEL MESSAGE
@REM Example: call :log INFO "Starting..."
setlocal
set level=%1
set msg=%~2
for /f "tokens=1-3 delims=/:. " %%a in ("%date% %time%") do set ts=%%a-%%b-%%c %%d:%%e:%%f
echo [%ts%] [%level%] %msg%
endlocal & goto :eof

IF "%1"=="--help" (
  call :log INFO "Usage: run-steam-rust.bat [--help]"
  call :log INFO "."
  call :log INFO "Options:"
  call :log INFO "   --help            Show this help message"
  call :log INFO "."
  call :log INFO "Run NuShell script to install Steam and prompt for Rust (Facepunch) installation."
  call :log INFO "Target OS: Windows (Batch)"
  exit /b 0
)

IF NOT EXIST "C:\Program Files\Nu\bin\nu.exe" (
  call :log ERROR "NuShell not found at C:\Program Files\Nu\bin\nu.exe"
  exit /b 1
)

"C:\Program Files\Nu\bin\nu.exe" "%~dp0install-steam-rust.nu" %*
IF ERRORLEVEL 1 (
  call :log ERROR "NuShell script failed."
  exit /b 1
) ELSE (
  call :log SUCCESS "Steam + Rust automation completed."
  exit /b 0
) 