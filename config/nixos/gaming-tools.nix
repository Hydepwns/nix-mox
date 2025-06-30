# Gaming Validation Tools Configuration
# Add this to your NixOS configuration.nix or import it

{ config, lib, pkgs, ... }:

{
  # Add gaming validation tools to system packages
  environment.systemPackages = with pkgs; [
    # Hardware detection
    pciutils # lspci - for GPU detection
    mesa-demos # glxinfo - for OpenGL information

    # Audio system
    pulseaudio # pactl - for audio system detection

    # Security
    ufw # firewall status

    # Additional useful gaming tools
    vulkan-tools # vulkaninfo (already available)
    gamemode # gamemoded (already available)
    mangohud # performance monitoring (already available)

    # Gaming platforms
    steam # Steam (already available)
    lutris # Lutris (already available)
    wine # Wine (already available)
  ];

  # Optional: Enable UFW firewall service
  services.ufw = {
    enable = true;
    settings = {
      DEFAULT_INPUT_POLICY = "DROP";
      DEFAULT_OUTPUT_POLICY = "ACCEPT";
      DEFAULT_FORWARD_POLICY = "DROP";
    };
  };

  # Optional: Enable PipeWire for better audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };

  # Optional: Enable GameMode service
  services.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        softrealtime = "auto";
        ioprio = 0;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };
}
