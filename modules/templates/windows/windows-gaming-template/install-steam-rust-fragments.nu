# Windows Gaming Template - Fragment System Version
# This script provides backward compatibility with the original gaming template
# while using the new fragment system under the hood

# Load configuration from JSON (backward compatibility)
let config = (open config.json)

# Set environment variables for fragment system
$env.HOSTNAME = "gaming-pc"
$env.FEATURES = "gaming,performance"
$env.STEAM_PATH = $config.steam.installPath
$env.GAMES = "rust"
$env.PERFORMANCE_PROFILE = "high-performance"
$env.CI = $env.CI? | default "false"
$env.DRY_RUN = "false"

# Import the base fragment system
source ../fragments/base.nu

# Additional backward compatibility functions
def legacy-steam-setup [] {
    log "Running legacy Steam setup for backward compatibility..."

    # This function provides the exact same functionality as the original
    # install-steam-rust.nu script, but using the fragment system

    if ($config.steam.installPath | path exists) {
        log "Steam installation directory already exists"
    } else {
        log "Creating Steam installation directory..."
        mkdir $config.steam.installPath
    }

    # Create legacy config file for backward compatibility
    let runConfig = {
        steam_path: $config.steam.installPath,
        rust_path: $config.rust.installPath,
        rust_app_id: $config.rust.appId
    }
    $runConfig | to json | save run.json

    log "Legacy Steam setup completed"
}

def legacy-rust-setup [] {
    log "Running legacy Rust setup for backward compatibility..."

    # This ensures Rust is installed exactly as in the original script
    if "rust" in $env.GAMES {
        log "Rust installation will be handled by gaming fragment"
    }

    log "Legacy Rust setup completed"
}

# Run legacy setup functions
legacy-steam-setup
legacy-rust-setup

log "Windows Gaming Template (Fragment System) completed successfully!"
log "This version maintains full backward compatibility with the original template."
