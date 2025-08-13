{ config, lib, pkgs, ... }:

with lib;

# Gaming platforms configuration
# Handles Steam, Lutris, Heroic, and other gaming platforms

let
  cfg = config.services.gaming;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isx86_64) {
    # Gaming platforms
    programs = mkIf (cfg.platforms.steam || cfg.platforms.lutris || cfg.platforms.heroic) {
      steam = mkIf cfg.platforms.steam {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    };

    # System packages for gaming platforms and tools
    environment.systemPackages = with pkgs; [
      # Core gaming tools
      (mkIf cfg.platforms.lutris lutris)
      (mkIf cfg.platforms.heroic heroic)

      # Wine and compatibility
      wine
      wine64
      wineWowPackages.stable
      winetricks
      dxvk
      vkd3d

      # Additional gaming tools
      protontricks
    ];
  };
} 