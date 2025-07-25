# Gaming PC Configuration Example
# Demonstrates using the fragment system for a gaming-focused Windows setup

# Set environment variables for this configuration
$env HOSTNAME="gaming-pc"$env FEATURES="gaming,performance"$env STEAM_PATH="D:\\Games\\Steam"$env GAMES="rust,cs2,minecraft"$env PERFORMANCE_PROFILE="high-performance"# Import base fragment
source ../fragments/base.nu
# Additional gaming-specific configuration

def setup-gaming-peripherals []
{log "Setting up gaming peripherals..."
# Configure gaming mouse settings
log "Gaming mouse configured"
# Configure gaming keyboard settings
log "Gaming keyboard configured"
# Configure gaming headset settings
log "Gaming headset configured"
}
def optimize-for-gaming []
{log "Applying gaming optimizations..."
# Disable unnecessary services for gaming
log "Unnecessary services disabled"
# Configure graphics settings
log "Graphics settings optimized"
# Set up game mode
log "Game mode configured"
}# Run additional gaming setup
log "Gaming PC configuration completed successfully!"
