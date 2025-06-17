{ pkgs }:

pkgs.writeScriptBin "configure-wine" ''
  #!${pkgs.bash}/bin/bash

  # Configuration script for Wine gaming setup
  # This script sets up a Wine prefix with optimal settings for gaming

  # Set Wine prefix
  export WINEPREFIX=~/.wine
  export WINEARCH=win64

  # Function to log messages
  log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  }

  # Check if running in gaming shell
  if ! command -v wine &> /dev/null; then
    echo "Error: Please run this script from the gaming shell (nix develop .#gaming)"
    exit 1
  fi

  # Create Wine prefix if it doesn't exist
  if [ ! -d "$WINEPREFIX" ]; then
    log "Creating new Wine prefix..."
    wineboot -i
  fi

  # Install essential components
  log "Installing essential components..."
  winetricks -q d3dx9 vcrun2019 vcrun2017 vcrun2015 vcrun2013 vcrun2010 vcrun2008 vcrun2005

  # Install audio components
  log "Installing audio components..."
  winetricks -q xact xact_x64

  # Install graphics components
  log "Installing graphics components..."
  winetricks -q dxvk vkd3d

  # Configure Wine settings
  log "Configuring Wine settings..."
  winetricks settings win7
  winetricks -q ddr=opengl
  winetricks -q videomemorysize=4096

  # Set up environment variables
  log "Setting up environment variables..."
  cat > ~/.config/wine-env << EOF
  export WINEPREFIX=~/.wine
  export WINEARCH=win64
  export DXVK_HUD=1
  export DXVK_STATE_CACHE=1
  export DXVK_STATE_CACHE_PATH=~/.cache/dxvk
  export __GL_SHADER_DISK_CACHE=1
  export __GL_SHADER_DISK_CACHE_PATH=~/.cache/gl-shaders
  EOF

  # Create cache directories
  mkdir -p ~/.cache/dxvk
  mkdir -p ~/.cache/gl-shaders

  log "Wine configuration complete!"
  log "To use these settings, source ~/.config/wine-env before running games"
  log "Example: source ~/.config/wine-env && lutris"
''
