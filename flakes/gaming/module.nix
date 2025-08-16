{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.gaming;
in
{
  # All gaming functionality is consolidated in this module
  # Individual feature modules have been merged for simplicity

  options.services.gaming = {
    enable = mkEnableOption "comprehensive gaming support";
    
    # Platform selection
    platforms = {
      steam = mkEnableOption "Steam gaming platform";
      lutris = mkEnableOption "Lutris gaming platform";
      heroic = mkEnableOption "Heroic Games Launcher";
      bottles = mkEnableOption "Bottles for Windows games";
      itch = mkEnableOption "itch.io desktop app";
    };
    
    # Performance options
    performance = {
      enable = mkEnableOption "gaming performance optimizations";
      
      cpuGovernor = mkOption {
        type = types.enum [ "performance" "schedutil" "ondemand" "powersave" ];
        default = "performance";
        description = "CPU frequency governor for gaming";
      };
      
      gpuMode = mkOption {
        type = types.enum [ "performance" "balanced" "battery" ];
        default = "performance";
        description = "GPU performance mode";
      };
      
      gameMode = mkEnableOption "GameMode for automatic optimizations";
      
      niceness = mkOption {
        type = types.int;
        default = -10;
        description = "Process niceness for games (lower = higher priority)";
      };
      
      ioScheduler = mkOption {
        type = types.enum [ "none" "mq-deadline" "bfq" "kyber" ];
        default = "mq-deadline";
        description = "I/O scheduler for SSDs";
      };
    };
    
    # Graphics options
    graphics = {
      mangohud = mkEnableOption "MangoHud overlay";
      vkbasalt = mkEnableOption "vkBasalt post-processing";
      gamescope = mkEnableOption "Gamescope compositor";
      
      shaderCache = {
        enable = mkEnableOption "shader cache management";
        
        location = mkOption {
          type = types.path;
          default = "/var/cache/gaming/shaders";
          description = "Shader cache location";
        };
        
        maxSize = mkOption {
          type = types.str;
          default = "10G";
          description = "Maximum shader cache size";
        };
      };
    };
    
    # Audio options
    audio = {
      lowLatency = mkEnableOption "low-latency audio configuration";
      
      sampleRate = mkOption {
        type = types.int;
        default = 48000;
        description = "Audio sample rate";
      };
      
      quantum = mkOption {
        type = types.int;
        default = 512;
        description = "Audio quantum (buffer size)";
      };
    };
    
    # Network options
    networking = {
      optimize = mkEnableOption "network optimizations for gaming";
      
      tcpCongestion = mkOption {
        type = types.enum [ "bbr" "cubic" "reno" ];
        default = "bbr";
        description = "TCP congestion control algorithm";
      };
      
      openPorts = mkEnableOption "open common gaming ports";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Base gaming configuration
    {
      # Enable 32-bit support (required for many games)
      hardware.graphics.enable32Bit = true;
      
      # Basic gaming packages
      environment.systemPackages = with pkgs; [
        # Core tools
        vulkan-tools
        vulkan-loader
        vulkan-validation-layers
        
        # Performance monitoring
        mangohud
        goverlay
        
        # Compatibility layers
        wine
        wine64
        wineWowPackages.staging
        winetricks
        
        # Utilities
        gamemode
        gamescope
        
        # Additional libraries for anticheat support
        glibc
        gcc.cc.lib
      ];
      
      # Enable gamemode group
      users.groups.gamemode = { };
      
      # Basic kernel parameters for gaming
      boot.kernelParams = [
        "transparent_hugepage=always"
        "mitigations=off"
      ];
      
      # Increase file handle limits
      systemd.user.extraConfig = ''
        DefaultLimitNOFILE=1048576
      '';
      
      security.pam.loginLimits = [
        {
          domain = "@users";
          type = "soft";
          item = "nofile";
          value = "1048576";
        }
        {
          domain = "@users";
          type = "hard";
          item = "nofile";
          value = "1048576";
        }
      ];
    }
    
    # Steam configuration
    (mkIf cfg.platforms.steam {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = cfg.graphics.gamescope;
        
        # Note: Proton GE will be installed via protonup tool
        # extraCompatPackages would go here if we had packaged versions
      };
      
      # Steam-specific packages
      environment.systemPackages = with pkgs; [
        steam-run
        steamcmd
        protontricks
        protonup-qt
        protonup  # CLI tool for managing Proton GE versions
      ];
      
      # Environment variables for Steam and Proton
      environment.sessionVariables = {
        # Path for custom Proton versions
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
    })
    
    # Lutris configuration
    (mkIf cfg.platforms.lutris {
      environment.systemPackages = with pkgs; [
        lutris
        (lutris.override {
          extraLibraries = pkgs: [
            # Additional libraries for compatibility
          ];
        })
      ];
    })
    
    # Heroic configuration
    (mkIf cfg.platforms.heroic {
      environment.systemPackages = with pkgs; [
        heroic
        legendary-gl  # CLI for Epic Games
      ];
    })
    
    # Bottles configuration
    (mkIf cfg.platforms.bottles {
      environment.systemPackages = with pkgs; [
        bottles
      ];
    })
    
    # Performance optimizations
    (mkIf cfg.performance.enable {
      # CPU governor
      powerManagement.cpuFreqGovernor = cfg.performance.cpuGovernor;
      
      # I/O scheduler
      services.udev.extraRules = ''
        # Set I/O scheduler for NVMe
        ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="${cfg.performance.ioScheduler}"
        # Set I/O scheduler for SATA SSDs
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="${cfg.performance.ioScheduler}"
      '';
      
      # Additional kernel parameters
      boot.kernelParams = [
        "processor.max_cstate=1"
        "intel_idle.max_cstate=1"
        "idle=poll"
        "mitigations=off"  # Disable CPU exploit mitigations for performance
      ];
    })
    
    # GameMode configuration
    (mkIf cfg.performance.gameMode {
      programs.gamemode = {
        enable = true;
        settings = {
          general = {
            renice = cfg.performance.niceness;
            softrealtime = "auto";
            ioprio = 0;
          };
          
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
            nv_powermizer_mode = if cfg.performance.gpuMode == "performance" then 1 else 0;
            amd_performance_level = cfg.performance.gpuMode;
          };
          
          cpu = {
            park_cores = "no";
            pin_cores = "yes";
          };
        };
      };
    })
    
    # Graphics enhancements
    (mkIf cfg.graphics.mangohud {
      environment.systemPackages = [ pkgs.mangohud ];
      
      environment.variables = {
        MANGOHUD = "1";
      };
    })
    
    (mkIf cfg.graphics.vkbasalt {
      environment.systemPackages = [ pkgs.vkbasalt ];
      
      environment.variables = {
        ENABLE_VKBASALT = "1";
      };
    })
    
    (mkIf cfg.graphics.gamescope {
      environment.systemPackages = [ pkgs.gamescope ];
    })
    
    # Shader cache management
    (mkIf cfg.graphics.shaderCache.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.graphics.shaderCache.location} 0755 root root -"
      ];
      
      # Periodic cleanup of old shaders
      systemd.services.shader-cache-cleanup = {
        description = "Clean up old shader cache";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.findutils}/bin/find ${cfg.graphics.shaderCache.location} -type f -atime +30 -delete";
        };
      };
      
      systemd.timers.shader-cache-cleanup = {
        description = "Clean up old shader cache weekly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
      };
    })
    
    # Audio optimizations
    (mkIf cfg.audio.lowLatency {
      services.pipewire.extraConfig.pipewire = {
        "context.properties" = {
          "default.clock.rate" = cfg.audio.sampleRate;
          "default.clock.quantum" = cfg.audio.quantum;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 2048;
        };
      };
    })
    
    # Network optimizations
    (mkIf cfg.networking.optimize {
      boot.kernel.sysctl = {
        # TCP optimizations
        "net.ipv4.tcp_congestion_control" = mkDefault cfg.networking.tcpCongestion;
        "net.ipv4.tcp_fastopen" = mkDefault 3;
        "net.ipv4.tcp_mtu_probing" = mkDefault 1;
        
        # Buffer sizes
        "net.core.rmem_max" = mkDefault 134217728;
        "net.core.wmem_max" = mkDefault 134217728;
        "net.ipv4.tcp_rmem" = mkDefault "4096 87380 134217728";
        "net.ipv4.tcp_wmem" = mkDefault "4096 65536 134217728";
        
        # Reduce latency
        "net.ipv4.tcp_low_latency" = mkDefault 1;
        "net.ipv4.tcp_timestamps" = mkDefault 0;
      };
    })
    
    # Open gaming ports
    (mkIf cfg.networking.openPorts {
      networking.firewall.allowedTCPPorts = [
        27015  # Source games
        25565  # Minecraft
        7777   # Terraria
        8080   # Various games
        3074   # Xbox Live
        1935   # RTMP
        3478   # STUN
        3479   # STUN
        3480   # STUN
      ];
      
      networking.firewall.allowedUDPPorts = [
        27015  # Source games
        25565  # Minecraft
        7777   # Terraria
        5353   # mDNS
        3074   # Xbox Live
        88     # Xbox Live
        500    # Xbox Live
        3544   # Xbox Live
        4500   # Xbox Live
        3478   # STUN
        3479   # STUN
        3480   # STUN
      ];
    })
  ]);
}