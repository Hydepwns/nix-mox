{ pkgs }:
pkgs.mkShell {
  buildInputs = [
    # Core gaming platforms
    pkgs.steam
    pkgs.lutris
    pkgs.heroic
    pkgs.mangohud

    # Wine and compatibility
    pkgs.wine
    pkgs.wine64
    pkgs.wineWowPackages.stable
    pkgs.winetricks
    pkgs.dxvk
    pkgs.vkd3d

    # Performance optimization
    pkgs.gamemode
    pkgs.mesa
    pkgs.vulkan-tools
    pkgs.vulkan-validation-layers
    pkgs.vulkan-headers
    pkgs.vulkan-loader
    pkgs.vulkan-extension-layer
    pkgs.vulkan-utility-libraries

    # Audio support
    pkgs.pipewire
    pkgs.pulseaudio

    # System monitoring
    pkgs.htop
    pkgs.glmark2

    # Additional gaming tools
    pkgs.protontricks
    pkgs.dosbox
    pkgs.scummvm

    # Scripts and utilities
    # pkgs.callPackage ./scripts/configure-wine.nix { }
  ];

  shellHook = ''
    # Set up environment variables for optimal gaming performance
    export DXVK_HUD=1
    export DXVK_STATE_CACHE=1
    export DXVK_STATE_CACHE_PATH=~/.cache/dxvk
    export __GL_SHADER_DISK_CACHE=1
    export __GL_SHADER_DISK_CACHE_PATH=~/.cache/gl-shaders
    export __GL_SYNC_TO_VBLANK=0
    export __GL_THREADED_OPTIMIZATIONS=1
    export MESA_GL_VERSION_OVERRIDE=4.5
    export MESA_GLSL_VERSION_OVERRIDE=450

    # Create cache directories
    mkdir -p ~/.cache/dxvk
    mkdir -p ~/.cache/gl-shaders

    # Function to show gaming help menu
    show_gaming_help() {
      echo "🎮 Welcome to the nix-mox Gaming shell!"
      echo ""
      echo "🔧 Gaming Platforms"
      echo "------------------"
      echo "steam:"
      echo "    Commands:"
      echo "    - steam                         # Start Steam"
      echo "    - protontricks                  # Configure Proton games"
      echo ""
      echo "lutris:"
      echo "    Commands:"
      echo "    - lutris                        # Start Lutris"
      echo "    - configure-wine                # Set up Wine prefix"
      echo ""
      echo "heroic:"
      echo "    Commands:"
      echo "    - heroic                        # Start Heroic Games Launcher"
      echo ""
      echo "🍷 Wine & Compatibility"
      echo "----------------------"
      echo "wine: (v${pkgs.wine.version})"
      echo "    Commands:"
      echo "    - wine                          # Run Windows applications"
      echo "    - winetricks                    # Configure Wine"
      echo "    - winecfg                       # Wine configuration"
      echo ""
      echo "dxvk: (v${pkgs.dxvk.version})"
      echo "    Commands:"
      echo "    - dxvk-cache-tool               # Manage DXVK cache"
      echo ""
      echo "⚡ Performance Tools"
      echo "-------------------"
      echo "mangohud:"
      echo "    Commands:"
      echo "    - mangohud                      # Start MangoHud"
      echo "    - mangohud --dlsym              # Use dlsym hooking"
      echo ""
      echo "gamemode:"
      echo "    Commands:"
      echo "    - gamemode                      # Start GameMode"
      echo "    - gamemoderun <command>         # Run command with GameMode"
      echo ""
      echo "vulkan-tools:"
      echo "    Commands:"
      echo "    - vulkaninfo                    # Display Vulkan information"
      echo "    - vkcube                        # Vulkan cube demo"
      echo ""
      echo "mesa:"
      echo "    Commands:"
      echo "    - glxinfo                       # Display OpenGL information"
      echo "    - glmark2                       # OpenGL benchmark"
      echo ""
      echo "📊 System Monitoring"
      echo "-------------------"
      echo "htop:"
      echo "    Commands:"
      echo "    - htop                          # Interactive process viewer"
      echo ""
      echo "🎯 League of Legends Setup"
      echo "------------------------"
      echo "1. Quick Setup:"
      echo "   ./scripts/configure-league.sh    # Configure League Wine prefix"
      echo ""
      echo "2. Launch League of Legends:"
      echo "   ./scripts/launch-league.sh       # Launch with optimal settings"
      echo "   league-launch                    # Alias for quick launch"
      echo ""
      echo "3. Manual Setup:"
      echo "   export WINEPREFIX=~/.wine-league"
      echo "   export WINEARCH=win64"
      echo "   wineboot -i"
      echo "   winetricks -q d3dx9 vcrun2019 dxvk vkd3d xact xact_x64"
      echo "   winetricks settings win7"
      echo ""
      echo "4. Launch with Lutris:"
      echo "   - Install League through Lutris"
      echo "   - Set Wine prefix to ~/.wine-league"
      echo "   - Enable DXVK and VKD3D"
      echo ""
      echo "5. Performance Optimization:"
      echo "   - Run with: gamemoderun mangohud wine LeagueClient.exe"
      echo "   - Enable GameMode for CPU/GPU optimization"
      echo "   - Use MangoHud for FPS monitoring"
      echo ""
      echo "🔧 Environment Variables Set:"
      echo "DXVK_HUD=1                          # Show DXVK HUD"
      echo "DXVK_STATE_CACHE=1                  # Enable DXVK state cache"
      echo "__GL_SHADER_DISK_CACHE=1           # Enable shader cache"
      echo "__GL_SYNC_TO_VBLANK=0              # Disable vsync"
      echo "__GL_THREADED_OPTIMIZATIONS=1      # Enable threaded optimizations"
      echo ""
      echo "💡 Quick Commands:"
      echo "league-setup                        # Configure League of Legends"
      echo "league-launch                       # Launch League of Legends"
      echo "wine-setup                          # Configure general Wine prefix"
      echo "gaming-help                         # Show this help menu"
      echo "gaming-test                         # Test gaming shell setup"
      echo ""
      echo "For more information, see docs/gaming.md"
    }

    # Create convenient aliases
    alias league-setup='./devshells/gaming/scripts/configure-league.sh'
    alias league-launch='./devshells/gaming/scripts/launch-league.sh'
    alias wine-setup='configure-wine'
    alias gaming-help='show_gaming_help'
    alias gaming-test='./devshells/gaming/scripts/test-gaming.sh'
    alias which-shell='echo "You are in the nix-mox gaming shell"'

    # Show initial help menu
    show_gaming_help

    echo ""
    echo "💡 Tip: Type 'gaming-help' to show this menu again"
    echo "💡 Tip: Type 'league-setup' to configure League of Legends"
    echo "💡 Tip: Type 'league-launch' to launch League of Legends"
    echo "💡 Tip: Type 'wine-setup' to configure general Wine prefix"
    echo "💡 Tip: Type 'gaming-test' to test your gaming setup"
    echo ""
  '';
}
