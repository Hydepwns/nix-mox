#!/bin/bash

# League of Legends Launch Script for nix-mox
# This script launches League of Legends with proper Wine configuration
#
# Requirements:
# ============
# 1. System Requirements:
#    - NixOS with nix-mox safe-configuration platform
#    - Wine 10.0+ (wineWowPackages.stable)
#    - wine64 binary available in PATH
#    - winetricks available in PATH
#
# 2. Gaming Shell Requirements:
#    - nix-mox gaming devshell: nix develop .#gaming
#    - GameMode for CPU/GPU optimization
#    - MangoHud for FPS monitoring
#    - DXVK for DirectX to Vulkan translation
#    - VKD3D for DirectX 12 to Vulkan translation
#
# 3. Wine Prefix Requirements:
#    - 64-bit Wine prefix at ~/.wine-league
#    - Windows 7 compatibility mode
#    - DirectX 9 components installed (d3dx9)
#    - Visual C++ runtimes (optional but recommended)
#
# 4. Hardware Requirements:
#    - Graphics card with Vulkan support
#    - At least 4GB RAM
#    - Stable internet connection for League of Legends
#
# 5. Installation Prerequisites:
#    - League of Legends installer downloaded
#    - Wine prefix configured via: ./devshells/gaming/scripts/configure-league.sh
#
# Usage:
# ======
# 1. Enter gaming shell: nix develop .#gaming
# 2. Run this script: ./devshells/gaming/scripts/launch-league.sh
#
# Troubleshooting:
# ===============
# - If Wine prefix doesn't exist: Run configure-league.sh first
# - If League not installed: Download and install via wine64 installer.exe
# - If graphics issues: Ensure DXVK/VKD3D are properly configured
# - If performance issues: Check GameMode and MangoHud are working

echo "🎮 Launching League of Legends..."

# Set Wine environment variables
export WINEPREFIX=~/.wine-league
export WINEARCH=win64

# Set performance and compatibility environment variables
export DXVK_HUD=1
export DXVK_STATE_CACHE=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SYNC_TO_VBLANK=0
export __GL_THREADED_OPTIMIZATIONS=1

# Check if League of Legends is installed
LEAGUE_PATH="$WINEPREFIX/drive_c/Riot Games/League of Legends/LeagueClient.exe"

if [ ! -f "$LEAGUE_PATH" ]; then
    echo "❌ League of Legends not found at: $LEAGUE_PATH"
    echo "📥 Please install League of Legends first:"
    echo "   1. Download League of Legends installer from https://na.leagueoflegends.com/"
    echo "   2. Run: wine64 League_of_Legends_installer.exe"
    echo "   3. Follow the installation process"
    exit 1
fi

echo "✅ League of Legends found!"
echo "🚀 Starting League Client..."

# Launch League of Legends with performance optimizations
cd "$(dirname "$LEAGUE_PATH")"
gamemoderun mangohud wine64 LeagueClient.exe

echo "🎮 League of Legends launched!"
