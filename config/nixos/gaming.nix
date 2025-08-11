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
        # Only include 32-bit packages on x86_64 systems
        extraPackages32 = if pkgs.stdenv.hostPlatform.isx86_64 then with pkgs.pkgsi686Linux; [
          vaapiVdpau
          libvdpau-va-gl
        ] else [];
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

    # Audio configuration with low-latency optimizations
    services = mkIf cfg.audio.enable {
      # PipeWire for modern audio with gaming optimizations
      pipewire = mkIf cfg.audio.pipewire {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = cfg.audio.jack;
        
        # Low-latency configuration for gaming using extraConfig
        extraConfig.pipewire = {
          "99-gaming-optimization" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 32;
              "default.clock.min-quantum" = 32;
              "default.clock.max-quantum" = 32;
            };
          };
        };
        
        extraConfig.pipewire-pulse = {
          "99-gaming-pulse" = {
            "context.properties" = {
              "log.level" = 2;
            };
            "pulse.properties" = {
              "pulse.min.req" = "32/48000";
              "pulse.default.req" = "32/48000";
              "pulse.max.req" = "32/48000";
              "pulse.min.quantum" = "32/48000";
              "pulse.max.quantum" = "32/48000";
            };
          };
        };
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
      enable = true;
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

    # Kernel modules for gaming - include both Intel and AMD virtualization support
    boot.kernelModules = [
      "kvm-intel" # For Intel virtualization
      "kvm-amd"   # For AMD virtualization
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
        # Memory management optimizations
        "transparent_hugepage=madvise" # Better memory allocation
        "vm.swappiness=1" # Minimize swapping for gaming
        "vm.vfs_cache_pressure=50" # Balance cache pressure
        "vm.dirty_ratio=3" # Reduce dirty page ratio for better responsiveness
        "vm.dirty_background_ratio=1" # Background writeback threshold
        # Gaming-specific kernel parameters
        "preempt=full" # Full preemption for lower latency
        "rcu_nocb_poll" # RCU callback polling for smoother gameplay
        "nohz_full=1-7" # Disable timer ticks on cores 1-7 for gaming
        "isolcpus=1-7" # Isolate cores for gaming processes
        "processor.max_cstate=1" # Limit CPU C-states for consistent performance
        "intel_idle.max_cstate=1" # Intel-specific idle state limitation
        "idle=poll" # Polling idle for minimal latency
        # Graphics optimizations
        "nvidia.NVreg_UsePageAttributeTable=1" # NVIDIA PAT optimization
        "nvidia.NVreg_InitializeSystemMemoryAllocations=0" # Faster allocation
        "nvidia.NVreg_DynamicPowerManagement=0x00" # Disable power management
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Preserve VRAM
      ];
    };

    # CPU governor and performance optimizations (merged with previous definition)

    # Additional performance tuning
    systemd.services.performance-tuning = {
      description = "Apply performance optimizations for gaming";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Set CPU governor to performance
        echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
        
        # Disable CPU idle states for lower latency
        echo 1 > /sys/devices/system/cpu/cpu*/power/energy_perf_bias 2>/dev/null || true
        
        # Set maximum CPU performance
        echo 0 > /sys/devices/system/cpu/cpuidle/sleep_disabled 2>/dev/null || true
        
        # I/O scheduler optimization - mq-deadline for SSDs, bfq for HDDs
        for disk in /sys/block/nvme*; do
          [ -e "$disk/queue/scheduler" ] && echo mq-deadline > "$disk/queue/scheduler" 2>/dev/null || true
        done
        
        for disk in /sys/block/sd*; do
          if [ -e "$disk/queue/rotational" ] && [ "$(cat "$disk/queue/rotational")" = "1" ]; then
            # HDD - use BFQ for better interactive performance
            echo bfq > "$disk/queue/scheduler" 2>/dev/null || true
          else
            # SSD - use mq-deadline for low latency
            echo mq-deadline > "$disk/queue/scheduler" 2>/dev/null || true
          fi
        done
        
        # Optimize NVMe queue depth for gaming
        for nvme in /sys/block/nvme*; do
          [ -e "$nvme/queue/nr_requests" ] && echo 32 > "$nvme/queue/nr_requests" 2>/dev/null || true
        done
        
        # NVIDIA-specific optimizations
        if [ -e /proc/driver/nvidia/version ]; then
          # Set NVIDIA GPU performance mode
          echo performance > /sys/bus/pci/devices/0000:01:00.0/power_state 2>/dev/null || true
          
          # Disable NVIDIA power management
          echo -1 > /sys/bus/pci/devices/0000:01:00.0/power/autosuspend_delay_ms 2>/dev/null || true
          echo on > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null || true
        fi
        
        # Intel integrated graphics optimizations
        if [ -e /sys/class/drm/card0/gt_max_freq_mhz ]; then
          # Set maximum GPU frequency
          cat /sys/class/drm/card0/gt_max_freq_mhz > /sys/class/drm/card0/gt_min_freq_mhz 2>/dev/null || true
        fi
      '';
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
