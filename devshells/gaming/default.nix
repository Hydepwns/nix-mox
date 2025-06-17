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
    pkgs.vulkan-tools-lunarg
    pkgs.vulkan-validation-layers-lunarg
    pkgs.vulkan-headers-lunarg
    pkgs.vulkan-loader-lunarg
    pkgs.vulkan-extension-layer-lunarg
    pkgs.vulkan-utility-libraries-lunarg
  ];

  shellHook = ''
    echo "Welcome to the nix-mox Gaming shell!"
    echo ""
    echo "🔧 Gaming Tools"
    echo "----------------"
    echo "steam: (v${pkgs.steam.version})"
    echo "    Commands:"
    echo "    - steam                         # Start Steam"
    echo ""
    echo "wine: (v${pkgs.wine.version})"
    echo "    Commands:"
    echo "    - wine                          # Run Windows applications"
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
    echo "For more information, see docs/."
  '';
}
