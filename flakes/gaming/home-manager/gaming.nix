# Home-manager gaming configuration
{ config, lib, pkgs, ... }:

with lib;

{
  # User-specific gaming configuration
  home.packages = with pkgs; [
    # User gaming tools
    discord
    obs-studio
  ];
  
  # Gaming-related dotfiles
  home.file = {
    # MangoHud configuration
    ".config/MangoHud/MangoHud.conf".text = ''
      fps_limit=0
      vsync=0
      cpu_stats
      cpu_temp
      gpu_stats
      gpu_temp
      ram
      vram
      frame_timing
      position=top-left
      font_size=24
      background_alpha=0.5
    '';
  };
}