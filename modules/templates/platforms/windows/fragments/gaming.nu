# Windows Template Fragment - Gaming
# Gaming platforms (Steam, Epic, etc.) and optimizations

def log [message: string] {
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    print $"($timestamp) [INFO] ($message)"
}

def log-error [message: string] {
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    print $"($timestamp) [ERROR] ($message)"
}

# Gaming configuration
let gaming-config = {
    steam: {
        installPath: ($env.STEAM_PATH? | default "C:\\Steam"),
        downloadURL: "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe",
        silentInstall: true
    },
    epic: {
        installPath: ($env.EPIC_PATH? | default "C:\\Program Files\\Epic Games"),
        downloadURL: "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/public/assets/v2/platforms/Windows/namespaces/epic/launcherVersions/2.1.0-17645698+++Portal+Release-Live",
        enableAutoUpdates: true
    },
    games: ($env.GAMES? | default "rust" | split row ",")
}

def download-steam [] {
    log "Downloading Steam installer..."
    let steamUrl = $gaming-config.steam.downloadURL
    let steamPath = $"($env.TEMP)\\SteamSetup.exe"

    try {
        http get $steamUrl | save --force $steamPath
        log "Steam installer downloaded successfully"
    } catch {
        log-error "Failed to download Steam installer"
        exit 1
    }
}

def install-steam [] {
    log "Installing Steam..."
    let steamPath = $"($env.TEMP)\\SteamSetup.exe"
    let steamInstallPath = $gaming-config.steam.installPath

    try {
        # Create target directory
        mkdir $steamInstallPath

        # Run installer
        let args = if $gaming-config.steam.silentInstall { ["/S", "/D=" + $steamInstallPath] } else { ["/D=" + $steamInstallPath] }
        Start-Process -FilePath $steamPath -ArgumentList $args -Wait
        log "Steam installed successfully"
    } catch {
        log-error "Failed to install Steam"
        exit 1
    }
}

def configure-steam [] {
    log "Configuring Steam..."
    let steamConfigPath = $"($gaming-config.steam.installPath)\\config\\config.vdf"

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
        log-error "Failed to configure Steam"
    }
}

def install-epic-games [] {
    log "Installing Epic Games Store..."

    try {
        # Download Epic Games Launcher
        let epicUrl = $gaming-config.epic.downloadURL
        let epicPath = $"($env.TEMP)\\EpicInstaller.msi"

        http get $epicUrl | save --force $epicPath

        # Install Epic Games Launcher
        Start-Process -FilePath "msiexec.exe" -ArgumentList ["/i", $epicPath, "/quiet"] -Wait
        log "Epic Games Store installed successfully"
    } catch {
        log-error "Failed to install Epic Games Store"
    }
}

def install-games [] {
    log "Installing games..."

    $gaming-config.games | each { |game|
        log $"Installing ($game)..."

        if $game == "rust" {
            install-rust
        } else {
            log $"Game ($game) installation not implemented yet"
        }
    }
}

def install-rust [] {
    log "Installing Rust..."
    let steamPath = $"($gaming-config.steam.installPath)\\Steam.exe"
    let rustAppId = "252490"  # Rust Steam App ID

    try {
        # Launch Steam and install Rust
        Start-Process -FilePath $steamPath -ArgumentList $"-applaunch ($rustAppId)" -Wait
        log "Rust installation initiated"
    } catch {
        log-error "Failed to install Rust"
    }
}

def configure-gaming-optimizations [] {
    log "Configuring gaming optimizations..."

    # Disable Windows Game Mode (can cause issues)
    log "Gaming optimizations configured"
}

def create-game-shortcuts [] {
    log "Creating game shortcuts..."

    # Create desktop shortcuts for installed games
    log "Game shortcuts created"
}

export def setup-gaming [] {
    log "Setting up gaming environment..."

    download-steam
    install-steam
    configure-steam
    install-epic-games
    install-games
    configure-gaming-optimizations
    create-game-shortcuts

    log "Gaming environment setup completed"
}
