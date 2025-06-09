# Windows Gaming Template: Steam and Rust Installation Script
# This script automates the installation of Steam and Rust on Windows

# CI/CD configuration
let isCI = $env.CI? == "true"
let logLevel = if $isCI { "debug" } else { "info" }

# Helper functions
def log [message: string] {
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    if $logLevel == "debug" {
        print $"($timestamp) [DEBUG] ($message)"
    } else {
        print $"($timestamp) [INFO] ($message)"
    }
}

def check-prerequisites [] {
    log "Checking prerequisites..."
    
    # Check if running as administrator
    let isAdmin = (whoami | str contains "Administrator")
    if not $isAdmin {
        error make {msg: "Script must be run as Administrator"}
    }
    
    # Check Windows version
    let winVer = (systeminfo | findstr /B /C:"OS Version")
    log $"Windows version: ($winVer)"
    
    # Check available disk space
    let freeSpace = (Get-PSDrive C | get free)
    if $freeSpace < 50GB {
        error make {msg: "Insufficient disk space. Need at least 50GB free."}
    }
}

def download-steam [] {
    log "Downloading Steam installer..."
    let steamUrl = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
    let steamPath = "C:\Windows\Temp\SteamSetup.exe"
    
    try {
        Invoke-WebRequest -Uri $steamUrl -OutFile $steamPath
        log "Steam installer downloaded successfully"
    } catch {
        error make {msg: "Failed to download Steam installer"}
    }
}

def install-steam [] {
    log "Installing Steam..."
    let steamPath = "C:\Windows\Temp\SteamSetup.exe"
    
    try {
        Start-Process -FilePath $steamPath -ArgumentList "/S" -Wait
        log "Steam installed successfully"
    } catch {
        error make {msg: "Failed to install Steam"}
    }
}

def install-rust [] {
    log "Installing Rust..."
    let steamPath = "C:\Program Files (x86)\Steam\Steam.exe"
    
    try {
        # Launch Steam and install Rust
        Start-Process -FilePath $steamPath -ArgumentList "-applaunch 252490" -Wait
        log "Rust installation initiated"
    } catch {
        error make {msg: "Failed to install Rust"}
    }
}

def configure-steam [] {
    log "Configuring Steam..."
    let steamConfigPath = "C:\Program Files (x86)\Steam\config\config.vdf"
    
    try {
        # Create or update Steam configuration
        $config = @"
"InstallConfigStore"
{
    "Software"
    {
        "Valve"
        {
            "Steam"
            {
                "AutoUpdateWindowEnabled"    "0"
                "AllowDownloadsDuringAnyApp"    "1"
                "StreamingThrottleEnabled"    "0"
                "AllowDownloadsWhileAnyAppRunning"    "1"
                "DownloadUsageTimestamp"    "0"
            }
        }
    }
}
"@
        $config | Out-File -FilePath $steamConfigPath -Encoding UTF8
        log "Steam configuration updated"
    } catch {
        error make {msg: "Failed to configure Steam"}
    }
}

def main [] {
    log "Starting Steam and Rust installation..."
    log $"CI Mode: ($isCI)"
    
    # Run installation steps
    check-prerequisites
    download-steam
    install-steam
    configure-steam
    install-rust
    
    log "Installation completed successfully"
}

# Run the main function
main 