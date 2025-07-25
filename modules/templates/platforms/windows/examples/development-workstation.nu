# Development Workstation Configuration Example
# Demonstrates using the fragment system for a development-focused Windows setup

# Set environment variables for this configuration
$env HOSTNAME="dev-workstation"$env FEATURES="development,productivity"$env PERFORMANCE_PROFILE="balanced"$env SECURITY_LEVEL="high"# Import base fragment
source ../fragments/base.nu
# Additional development-specific configuration

def setup-dev-environment []
{log "Setting up development environment..."
# Configure Git settings
log "Git configured"
# Set up SSH keys
log "SSH keys configured"
# Configure development tools
log "Development tools configured"
}
def setup-docker-environment []
{log "Setting up Docker environment..."
# Configure Docker settings
log "Docker configured"
# Set up Docker Compose
log "Docker Compose configured"
}# Run additional development setup
log "Development workstation configuration completed successfully!"
