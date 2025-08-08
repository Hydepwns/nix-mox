{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.gaming;
in
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

  config = mkIf cfg.enable {
    # Hardware configuration
    hardware = {
      # Graphics support (updated from opengl)
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = mkMerge [
          (with pkgs; [
            vaapiVdpau
            libvdpau-va-gl
          ])
          (mkIf (cfg.gpu.type == "amd" || cfg.gpu.amd.enable) (with pkgs; [
            amdvlk
            rocm-opencl-icd
            rocm-opencl-runtime
          ]))
          (mkIf (cfg.gpu.type == "intel" || cfg.gpu.intel.enable) (with pkgs; [
            intel-media-driver
            vaapiIntel
            vaapiVdpau
          ]))
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    };

    # NVIDIA configuration - simplified conditional
    hardware.nvidia = mkIf (cfg.gpu.type == "nvidia" || cfg.gpu.nvidia.enable) {
      modesetting.enable = cfg.gpu.nvidia.modesetting.enable;
      powerManagement.enable = cfg.gpu.nvidia.powerManagement.enable;
      open = cfg.gpu.nvidia.open;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      # Note: Prime configuration removed due to option conflicts
      # For hybrid setups, configure manually in hardware config
    };

    # Audio configuration
    services = mkIf cfg.audio.enable {
      # PipeWire for modern audio
      pipewire = mkIf cfg.audio.pipewire {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = cfg.audio.jack;
      };

      # PulseAudio (legacy support)
      pulseaudio = mkIf cfg.audio.pulseaudio {
        enable = false;
        support32Bit = true;
        package = pkgs.pulseaudioFull;
      };

      # X server video drivers for NVIDIA
      xserver.videoDrivers = mkIf (cfg.gpu.type == "nvidia" || cfg.gpu.nvidia.enable) [ "nvidia" ];
    };

    # Gaming platforms
    programs = mkIf (cfg.platforms.steam || cfg.platforms.lutris || cfg.platforms.heroic) {
      steam = mkIf cfg.platforms.steam {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    };

    # Performance optimizations
    powerManagement = mkIf cfg.performance.enable {
      cpuFreqGovernor = cfg.performance.cpuGovernor;
    };

    # System packages for gaming
    environment.systemPackages = with pkgs; [
      # Core gaming tools
      (mkIf cfg.platforms.lutris lutris)
      (mkIf cfg.platforms.heroic heroic)

      # Performance tools
      (mkIf cfg.performance.gamemode gamemode)
      (mkIf cfg.performance.mangohud mangohud)

      # Graphics tools
      vulkan-tools
      # vulkan-validation-layers
      # vulkan-headers
      # vulkan-loader
      # vulkan-extension-layer
      # vulkan-utility-libraries

      # Wine and compatibility
      wine
      wine64
      wineWowPackages.stable
      winetricks
      dxvk
      vkd3d

      # System monitoring
      htop
      btop
      glmark2

      # Additional gaming tools
      protontricks
      # dosbox
      # scummvm

      # Audio tools
      # (mkIf cfg.audio.jack jack2)
      # (mkIf cfg.audio.jack qjackctl)
    ];

    # Kernel modules for gaming
    boot.kernelModules = [
      "kvm-intel" # For Intel virtualization
      "kvm-amd" # For AMD virtualization
    ];

    # Boot configuration for gaming
    boot = {
      # Use latest kernel for best gaming performance
      kernelPackages = mkDefault pkgs.linuxPackages_latest;

      # Kernel parameters for gaming
      kernelParams = [
        "intel_iommu=on" # For GPU passthrough
        "iommu=pt" # For GPU passthrough
        "nvidia-drm.modeset=1" # For NVIDIA modesetting
      ];
    };

    # Security settings for gaming
    security = {
      # Allow real-time scheduling for audio
      rtkit.enable = true;

      # Allow access to /dev/snd for audio
      wrappers = {
        pulseaudio = {
          source = "${pkgs.pulseaudio}/bin/pulseaudio";
          capabilities = "cap_sys_nice+ep";
          owner = "root";
          group = "audio";
        };
      };
    };

    # Networking for gaming
    networking = {
      # Open ports for gaming
      firewall = {
        allowedTCPPorts = [
          27015 # Steam
          27016 # Steam
          27017 # Steam
          27018 # Steam
          27019 # Steam
          27020 # Steam
          4380 # Steam
          4381 # Steam
        ];
        allowedUDPPorts = [
          27015 # Steam
          27016 # Steam
          27017 # Steam
          27018 # Steam
          27019 # Steam
          27020 # Steam
          4380 # Steam
          4381 # Steam
        ];
      };
    };
  };
}
