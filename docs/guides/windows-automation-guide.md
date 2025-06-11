# Windows Automation Guide

Terse guide for automating Steam + Rust installation on Windows using NuShell.

## Automation Flow

```mermaid
flowchart TD
    A[Windows System] --> B[Install NuShell]
    B --> C[Get Scripts]
    C --> D[Configure Task]
    D --> E[First Logon]
    E --> F[Install Steam]
    F --> G[Setup Rust]
```

## Script Components

```mermaid
graph TD
    A[Automation Assets] --> B[install-steam-rust.nu]
    A --> C[run-steam-rust.bat]
    A --> D[InstallSteamRust.xml]
    
    B --> E[NuShell Script]
    C --> F[Batch Wrapper]
    D --> G[Task Scheduler]
    
    E --> H[Steam Install]
    E --> I[Rust Setup]
```

## Quick Setup

1. **Get Scripts**
   ```bash
   # Build package
   nix build .#windows-automation-assets-sources
   
   # Copy to Windows
   cp result/* C:/nix-mox-scripts/
   ```

2. **Install NuShell**
   ```powershell
   # Using Chocolatey
   choco install nushell -y
   
   # Verify
   nu --version
   ```

3. **Configure Task**
   ```batch
   # Edit run-steam-rust.bat
   nu "%~dp0install-steam-rust.nu" %*
   ```

4. **Register Task**
   ```powershell
   # Import task
   schtasks /create /tn InstallSteamRust /xml InstallSteamRust.xml
   ```

## Task Configuration

```mermaid
graph TD
    A[Task Scheduler] --> B[Import XML]
    B --> C[Edit Action]
    C --> D[Set Path]
    D --> E[Save Task]
    
    C --> F[Program: run-steam-rust.bat]
    C --> G[Start in: Script Directory]
    C --> H[Trigger: At Logon]
```

## First Logon Process

```mermaid
flowchart TD
    A[User Logon] --> B[Task Trigger]
    B --> C[Run Batch]
    C --> D[Execute NuShell]
    D --> E[Install Steam]
    E --> F[Initialize Steam]
    F --> G[Prompt for Rust]
```

## Optional: Self-Destruct Task

```nu
# Add to install-steam-rust.nu
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
    
    B --> E[Security Note]
    E --> F[Store Credentials]
    F --> G[Risk Assessment]
```

For full headless installation details, see comments in `../scripts/windows/install-steam-rust.nu`.
