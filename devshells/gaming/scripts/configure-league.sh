#!/usr/bin/env bash
# League of Legends Wine prefix setup helper
# Enhanced version with performance optimizations and better error handling

set -e

# Configuration
export WINEPREFIX="$HOME/.wine-league"
export WINEARCH=win64

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages with colors
log() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to check if running in gaming shell
check_gaming_shell() {
  if ! command -v wine &> /dev/null; then
    error "Please run this from the gaming shell (nix develop .#gaming)"
    exit 1
  fi

  if ! command -v winetricks &> /dev/null; then
    error "winetricks not found. Please ensure you're in the gaming shell."
    exit 1
  fi
}

# Function to check system requirements
check_system_requirements() {
  info "Checking system requirements..."

  # Check for sufficient disk space (at least 10GB)
  local available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
  local required_space=10485760 # 10GB in KB

  if [ "$available_space" -lt "$required_space" ]; then
    warn "Low disk space. League of Legends requires at least 10GB free space."
    warn "Available: $((available_space / 1024 / 1024))GB"
  fi

  # Check for sufficient RAM (at least 4GB)
  local total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local required_ram=4194304 # 4GB in KB

  if [ "$total_ram" -lt "$required_ram" ]; then
    warn "Low RAM detected. League of Legends requires at least 4GB RAM."
    warn "Available: $((total_ram / 1024))MB"
  fi
}

# Function to create Wine prefix
create_wine_prefix() {
  if [ ! -d "$WINEPREFIX" ]; then
    log "Creating new Wine prefix for League of Legends..."
    log "Location: $WINEPREFIX"

    # Initialize Wine prefix
    wineboot -i

    # Wait for Wine to finish initialization
    log "Waiting for Wine prefix initialization..."
    sleep 5

    # Kill any remaining Wine processes
    wineserver -k 2> /dev/null || true
  else
    log "Wine prefix already exists at: $WINEPREFIX"
  fi
}

# Function to install required components
install_components() {
  log "Installing required components with winetricks..."

  # Core components for League of Legends
  local components=(
    "d3dx9"     # DirectX 9
    "vcrun2019" # Visual C++ 2019
    "vcrun2017" # Visual C++ 2017 (backup)
    "vcrun2015" # Visual C++ 2015 (backup)
    "dxvk"      # DirectX 11 support
    "vkd3d"     # DirectX 12 support
    "xact"      # Audio support
    "xact_x64"  # 64-bit audio support
    "dotnet48"  # .NET Framework 4.8
    "corefonts" # Windows core fonts
  )

  for component in "${components[@]}"; do
    log "Installing $component..."
    if winetricks -q "$component"; then
      log "✓ $component installed successfully"
    else
      warn "Failed to install $component, continuing..."
    fi
  done
}

# Function to configure Wine settings
configure_wine_settings() {
  log "Configuring Wine settings for optimal League of Legends performance..."

  # Set Windows version to 7 for compatibility
  log "Setting Windows version to win7..."
  winetricks settings win7

  # Configure graphics settings
  log "Configuring graphics settings..."
  winetricks -q ddr=opengl
  winetricks -q videomemorysize=4096

  # Configure audio settings
  log "Configuring audio settings..."
  winetricks -q sound=pulse
}

# Function to set up environment variables
setup_environment() {
  log "Setting up environment variables for optimal performance..."

  # Create environment file
  cat > "$HOME/.config/league-env" << 'EOF'
# League of Legends Wine Environment Variables
export WINEPREFIX="$HOME/.wine-league"
export WINEARCH=win64

# Performance optimizations
export DXVK_HUD=1
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="$HOME/.cache/dxvk"
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/gl-shaders"
export __GL_SYNC_TO_VBLANK=0
export __GL_THREADED_OPTIMIZATIONS=1
export MESA_GL_VERSION_OVERRIDE=4.5
export MESA_GLSL_VERSION_OVERRIDE=450

# Audio settings
export PULSE_LATENCY_MSEC=60

# Wine optimizations
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mshtml,mscoree="
EOF

  # Create cache directories
  mkdir -p "$HOME/.cache/dxvk"
  mkdir -p "$HOME/.cache/gl-shaders"

  log "Environment file created at: $HOME/.config/league-env"
}

# Function to create launch script
create_launch_script() {
  log "Creating League of Legends launch script..."

  cat > "$HOME/.local/bin/league-launch" << 'EOF'
#!/usr/bin/env bash
# League of Legends launch script with performance optimizations

# Source environment variables
source "$HOME/.config/league-env"

# Check if League Client is installed
LEAGUE_CLIENT="$WINEPREFIX/drive_c/Riot Games/League of Legends/LeagueClient.exe"
if [ ! -f "$LEAGUE_CLIENT" ]; then
    echo "League of Legends not found. Please install it first through Lutris."
    echo "Expected location: $LEAGUE_CLIENT"
    exit 1
fi

# Launch with performance optimizations
echo "Launching League of Legends with performance optimizations..."
gamemoderun mangohud wine "$LEAGUE_CLIENT"
EOF

  chmod +x "$HOME/.local/bin/league-launch"
  log "Launch script created at: $HOME/.local/bin/league-launch"
}

# Function to create Lutris configuration
create_lutris_config() {
  log "Creating Lutris configuration template..."

  cat > "$HOME/.config/lutris/games/league-of-legends.yml" << 'EOF'
# League of Legends Lutris Configuration
name: League of Legends
slug: league-of-legends
runner: wine
version: 1.0
game_slug: league-of-legends
installer_slug: league-of-legends
description: "League of Legends with optimized Wine configuration"
year: 2009
steamid: null
gogid: null
humbleid: null
config:
  wine:
    prefix: ~/.wine-league
    arch: win64
    version: lutris-7.2-2
  dxvk: true
  vkd3d: true
  gamemode: true
  mangohud: true
  env:
    DXVK_HUD: "1"
    DXVK_STATE_CACHE: "1"
    __GL_SHADER_DISK_CACHE: "1"
    __GL_SYNC_TO_VBLANK: "0"
    __GL_THREADED_OPTIMIZATIONS: "1"
EOF

  log "Lutris configuration created at: $HOME/.config/lutris/games/league-of-legends.yml"
}

# Function to show post-installation instructions
show_instructions() {
  echo ""
  echo -e "${GREEN}🎉 League of Legends Wine prefix setup complete!${NC}"
  echo ""
  echo -e "${BLUE}📋 Next Steps:${NC}"
  echo "1. Install League of Legends through Lutris:"
  echo "   - Open Lutris: lutris"
  echo "   - Search for 'League of Legends'"
  echo "   - Install using the official installer"
  echo ""
  echo "2. Configure Lutris to use this Wine prefix:"
  echo "   - Set Wine prefix to: $WINEPREFIX"
  echo "   - Enable DXVK and VKD3D"
  echo "   - Enable GameMode and MangoHud"
  echo ""
  echo "3. Launch options:"
  echo "   - Quick launch: league-launch"
  echo "   - Manual launch: source ~/.config/league-env && wine LeagueClient.exe"
  echo "   - With monitoring: gamemoderun mangohud wine LeagueClient.exe"
  echo ""
  echo -e "${BLUE}🔧 Performance Tips:${NC}"
  echo "• Use GameMode for CPU/GPU optimization"
  echo "• Use MangoHud for FPS monitoring"
  echo "• Enable DXVK for better DirectX performance"
  echo "• Disable vsync for lower latency"
  echo ""
  echo -e "${BLUE}📁 Files Created:${NC}"
  echo "• Wine prefix: $WINEPREFIX"
  echo "• Environment: $HOME/.config/league-env"
  echo "• Launch script: $HOME/.local/bin/league-launch"
  echo "• Lutris config: $HOME/.config/lutris/games/league-of-legends.yml"
  echo ""
  echo -e "${YELLOW}💡 To use this prefix in other applications:${NC}"
  echo "export WINEPREFIX=$WINEPREFIX"
  echo "export WINEARCH=win64"
  echo ""
}

# Main execution
main() {
  echo -e "${BLUE}🎮 League of Legends Wine Setup${NC}"
  echo "=================================="
  echo ""

  # Check prerequisites
  check_gaming_shell
  check_system_requirements

  # Setup process
  create_wine_prefix
  install_components
  configure_wine_settings
  setup_environment
  create_launch_script
  create_lutris_config

  # Show instructions
  show_instructions
}

# Run main function
main "$@"
