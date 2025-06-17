{ pkgs }:
pkgs.mkShell {
  buildInputs = [
    pkgs.steam
    pkgs.wine
    pkgs.lutris
    pkgs.mangohud
    pkgs.gamemode
    pkgs.mesa
    pkgs.vulkan-tools
    pkgs.vulkan-validation-layers
    pkgs.vulkan-headers
    pkgs.vulkan-loader
    pkgs.vulkan-extension-layer
    pkgs.vulkan-utility-libraries
    # League of Legends specific dependencies
    pkgs.winetricks
    pkgs.dxvk
    pkgs.vkd3d
    pkgs.wine64
    pkgs.wineWowPackages.stable
  ];

  shellHook = ''
    echo "Welcome to the nix-mox Gaming shell!"
    echo ""
    echo "🔧 Gaming Tools"
    echo "----------------"
    echo "steam:"
    echo "    Commands:"
    echo "    - steam                         # Start Steam"
    echo ""
    echo "wine: (v${pkgs.wine.version})"
    echo "    Commands:"
    echo "    - wine                          # Run Windows applications"
    echo "    - winetricks                    # Configure Wine"
    echo ""
    echo "lutris: (v${pkgs.lutris.version})"
    echo "    Commands:"
    echo "    - lutris                        # Start Lutris"
    echo ""
    echo "mangohud: (v${pkgs.mangohud.version})"
    echo "    Commands:"
    echo "    - mangohud                      # Start MangoHud"
    echo ""
    echo "gamemode: (v${pkgs.gamemode.version})"
    echo "    Commands:"
    echo "    - gamemode                      # Start GameMode"
    echo ""
    echo "mesa: (v${pkgs.mesa.version})"
    echo "    Commands:"
    echo "    - glxinfo                       # Display OpenGL information"
    echo ""
    echo "vulkan-tools: (v${pkgs.vulkan-tools.version})"
    echo "    Commands:"
    echo "    - vulkaninfo                    # Display Vulkan information"
    echo ""
    echo "🎮 League of Legends Setup"
    echo "------------------------"
    echo "1. Install League of Legends through Lutris"
    echo "2. Recommended Wine configuration:"
    echo "   - Use DXVK for DirectX 11 support"
    echo "   - Enable VKD3D for DirectX 12 support"
    echo "   - Use GameMode for performance optimization"
    echo "3. Performance tips:"
    echo "   - Run with MangoHud for FPS monitoring"
    echo "   - Use GameMode for CPU/GPU optimization"
    echo "   - Enable DXVK for better DirectX performance"
    echo ""
    echo "For more information, see docs/."
  '';
}
