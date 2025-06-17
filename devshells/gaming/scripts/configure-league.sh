#!/usr/bin/env bash
# League of Legends Wine prefix setup helper

set -e

export WINEPREFIX="$HOME/.wine-league"
export WINEARCH=win64

if ! command -v wine &> /dev/null; then
  echo "Please run this from the gaming shell (nix develop .#gaming)"
  exit 1
fi

if [ ! -d "$WINEPREFIX" ]; then
  echo "Creating new Wine prefix for League of Legends..."
  wineboot -i
fi

echo "Installing required components with winetricks..."
winetricks -q d3dx9 vcrun2019 dxvk vkd3d xact xact_x64

# Set Windows version to 7 for compatibility
echo "Configuring Windows version to win7..."
winetricks settings win7

echo "League of Legends Wine prefix setup complete!"
echo "Use this prefix by setting WINEPREFIX=~/.wine-league when launching Lutris or Wine."
