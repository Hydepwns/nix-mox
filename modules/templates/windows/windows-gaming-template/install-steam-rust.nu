# Windows Gaming Template: Steam and Rust Installation Script
# This script automates the installation of Steam and Rust on Windows

# Load configuration from JSON
let config = (open config.json)

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
    let steamUrl = $config.steam.downloadURL
    let steamPath = $"($env.TEMP)\\SteamSetup.exe"

    try {
        http get $steamUrl | save --force $steamPath
        log "Steam installer downloaded successfully"
    } catch {
        error make {msg: "Failed to download Steam installer"}
    }
}

def install-steam [] {
    log "Installing Steam..."
    let steamPath = $"($env.TEMP)\\SteamSetup.exe"
    let steamInstallPath = $config.steam.installPath

    try {
        # Create target directory
        mkdir $steamInstallPath

        # Run installer
        let args = if $config.steam.silentInstall { ["/S", "/D=" + $steamInstallPath] } else { ["/D=" + $steamInstallPath] }
        Start-Process -FilePath $steamPath -ArgumentList $args -Wait
        log "Steam installed successfully"
    } catch {
        error make {msg: "Failed to install Steam"}
    }
}

def install-rust [] {
    log "Installing Rust..."
    let steamPath = $"($config.steam.installPath)\\Steam.exe"
    let rustAppId = $config.rust.appId

    try {
        # Launch Steam and install Rust
        Start-Process -FilePath $steamPath -ArgumentList $"-applaunch ($rustAppId)" -Wait
        log "Rust installation initiated"
    } catch {
        error make {msg: "Failed to install Rust"}
    }
}

def configure-steam [] {
    log "Configuring Steam..."
    let steamConfigPath = $"($config.steam.installPath)\\config\\config.vdf"

    try {
        # Create or update Steam configuration
        let configContent = 'InstallConfigStore
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
}'
        $configContent | save --force $steamConfigPath
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

    # Create a config for the run script
    let runConfig = {
        steam_path: $config.steam.installPath,
        rust_path: $config.rust.installPath,
        rust_app_id: $config.rust.appId
    }
    $runConfig | to json | save run.json

    log "Installation completed successfully"
}

# Run the main function
main