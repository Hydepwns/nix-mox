@echo off
REM run-steam-rust.bat
REM Usage: run-steam-rust.bat [--help]
REM
REM Options:
REM   --help   Show this help message

IF "%1"=="--help" (
  echo Run NuShell script to install Steam and prompt for Rust (Facepunch) installation.
  echo.
  echo Options:
  echo   --help   Show this help message
  exit /b 0
)

IF NOT EXIST "C:\Program Files\Nu\bin\nu.exe" (
  echo [ERROR] NuShell not found at C:\Program Files\Nu\bin\nu.exe
  exit /b 1
)

"C:\Program Files\Nu\bin\nu.exe" "%~dp0install-steam-rust.nu" %*
IF ERRORLEVEL 1 (
  echo [ERROR] NuShell script failed.
  exit /b 1
) ELSE (
  echo [SUCCESS] Steam + Rust automation completed.
  exit /b 0
) 