{ config, lib, pkgs, ... }:

with lib;

# Gaming module options
# Defines all configuration options for the gaming module

{
  options.services.gaming = {
    enable = mkEnableOption "Enable comprehensive gaming support";

    gpu = {
      type = mkOption {
        type = types.enum [ "auto" "nvidia" "amd" "intel" "hybrid" ];
        default = "auto";
        description = "GPU type to configure for gaming";
      };

      nvidia = {
        enable = mkEnableOption "Enable NVIDIA GPU support";
        modesetting.enable = mkDefault true;
        powerManagement.enable = mkDefault true;
        open = mkDefault false;
        prime = {
          enable = mkDefault false;
          intelBusId = mkOption {
            type = types.str;
            description = "Intel GPU bus ID for hybrid setups";
          };
          nvidiaBusId = mkOption {
            type = types.str;
            description = "NVIDIA GPU bus ID for hybrid setups";
          };
        };
      };

      amd = {
        enable = mkEnableOption "Enable AMD GPU support";
        open = mkDefault true;
      };

      intel = {
        enable = mkEnableOption "Enable Intel GPU support";
        vaapi = mkDefault true;
        vdpau = mkDefault true;
      };
    };

    performance = {
      enable = mkEnableOption "Enable gaming performance optimizations";
      gamemode = mkEnableOption "Enable GameMode for CPU/GPU optimization";
      mangohud = mkEnableOption "Enable MangoHud for FPS monitoring";
      cpuGovernor = mkOption {
        type = types.enum [ "performance" "powersave" "ondemand" "conservative" ];
        default = "performance";
        description = "CPU governor for gaming";
      };
    };

    audio = {
      enable = mkEnableOption "Enable gaming audio support";
      pipewire = mkEnableOption "Enable PipeWire for low-latency audio";
      pulseaudio = mkEnableOption "Enable PulseAudio (legacy)";
      jack = mkEnableOption "Enable JACK audio server";
    };

    platforms = {
      steam = mkEnableOption "Enable Steam gaming platform";
      lutris = mkEnableOption "Enable Lutris gaming platform";
      heroic = mkEnableOption "Enable Heroic Games Launcher";
    };
  };
} 