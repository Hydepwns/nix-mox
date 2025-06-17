# Windows Automation Guide

## Automation Flow

```mermaid
flowchart TD
    A[Windows] --> B[Install NuShell]
    B --> C[Get Scripts]
    C --> D[Configure Task]
    D --> E[First Logon]
    E --> F[Install Steam]
    F --> G[Setup Rust]
```

## Script Components

```mermaid
graph TD
    A[Assets] --> B[install-steam-rust.nu]
    A --> C[run-steam-rust.bat]
    A --> D[InstallSteamRust.xml]
```

## Quick Setup

1. **Get Scripts**

   ```bash
   nix build .#windows-automation-assets-sources
   cp result/* C:/nix-mox-scripts/
   ```

2. **Install NuShell**

   ```powershell
   choco install nushell -y
   nu --version
   ```

3. **Configure Task**

   ```batch
   nu "%~dp0install-steam-rust.nu" %*
   ```

4. **Register Task**

   ```powershell
   schtasks /create /tn InstallSteamRust /xml InstallSteamRust.xml
   ```

## Task Configuration

```mermaid
graph TD
    A[Task Scheduler] --> B[Import XML]
    B --> C[Edit Action]
    C --> D[Set Path]
    D --> E[Save Task]
```

## First Logon Process

```mermaid
flowchart TD
    A[Logon] --> B[Task Trigger]
    B --> C[Run Script]
    C --> D[Install Steam]
    D --> E[Setup Rust]
```

## Optional: Self-Destruct Task

```nu
log_info "Deleting scheduled task"
try {
    run-external "schtasks.exe" "/Delete" "/TN" "InstallSteamRust" "/F"
    log_success "Task deleted"
} catch {
    log_warn "Could not delete task"
}
```

## Optional: Headless Install

```mermaid
graph TD
    A[SteamCMD] --> B[Login]
    B --> C[Install Rust]
    C --> D[Configure]
```

For full headless installation details, see comments in `../scripts/windows/install-steam-rust.nu`.

## Gaming Automation

```mermaid
flowchart TD
    A[Gaming VM] --> B[Install Steam]
    B --> C[Setup Rust]
    C --> D[Configure Game Mode]
    D --> E[Automated Updates]
```

### Game Mode Configuration

```powershell
# Enable Game Mode
reg add "HKLM\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f

# Disable Fullscreen Optimizations
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "C:\Program Files (x86)\Steam\steamapps\common\Rust\RustClient.exe" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f
```
