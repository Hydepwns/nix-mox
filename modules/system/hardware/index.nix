{ pkgs, config, lib, ... }:

let
  # GPU configurations
  gpu = { config, lib, pkgs, ... }: {
    options.hardware.gpu = {
      enable = lib.mkEnableOption "Enable GPU support";
      type = lib.mkOption {
        type = lib.types.enum [ "nvidia" "amd" "intel" "hybrid" ];
        default = "intel";
        description = "GPU type to configure";
      };
      nvidia = {
        enable = lib.mkEnableOption "Enable NVIDIA GPU support";
        modesetting.enable = lib.mkDefault true;
        powerManagement.enable = lib.mkDefault true;
        open = lib.mkDefault false;
        prime = {
          enable = lib.mkDefault false;
          intelBusId = lib.mkOption {
            type = lib.types.str;
            description = "Intel GPU bus ID for hybrid setups";
          };
          nvidiaBusId = lib.mkOption {
            type = lib.types.str;
            description = "NVIDIA GPU bus ID for hybrid setups";
          };
        };
      };
      amd = {
        enable = lib.mkEnableOption "Enable AMD GPU support";
        open = lib.mkDefault true;
      };
      intel = {
        enable = lib.mkEnableOption "Enable Intel GPU support";
        vaapi = lib.mkDefault true;
        vdpau = lib.mkDefault true;
      };
    };

    config = let
      cfg = config.hardware.gpu;
    in lib.mkIf cfg.enable {
      # NVIDIA configuration
      hardware.nvidia = lib.mkIf (cfg.type == "nvidia" || cfg.nvidia.enable) {
        enable = true;
        modesetting.enable = cfg.nvidia.modesetting.enable;
        powerManagement.enable = cfg.nvidia.powerManagement.enable;
        open = cfg.nvidia.open;
        prime = lib.mkIf cfg.nvidia.prime.enable {
          enable = true;
          intelBusId = cfg.nvidia.prime.intelBusId;
          nvidiaBusId = cfg.nvidia.prime.nvidiaBusId;
        };
      };

      # AMD configuration
      hardware.opengl.extraPackages = lib.mkIf (cfg.type == "amd" || cfg.amd.enable) (with pkgs; [
        amdvlk
        rocm-opencl-icd
        rocm-opencl-runtime
      ]);

      # Intel configuration
      hardware.opengl.extraPackages = lib.mkIf (cfg.type == "intel" || cfg.intel.enable) (with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
      ]);

      # OpenGL configuration
      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    };
  };

  # Audio configurations
  audio = { config, lib, pkgs, ... }: {
    options.hardware.audio = {
      enable = lib.mkEnableOption "Enable audio support";
      type = lib.mkOption {
        type = lib.types.enum [ "pipewire" "pulseaudio" "alsa" ];
        default = "pipewire";
        description = "Audio system to use";
      };
      pipewire = {
        enable = lib.mkEnableOption "Enable PipeWire audio";
        alsa.enable = lib.mkDefault true;
        alsa.support32Bit = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
        jack.enable = lib.mkDefault false;
        bluetooth.enable = lib.mkDefault true;
      };
      pulseaudio = {
        enable = lib.mkEnableOption "Enable PulseAudio";
        support32Bit = lib.mkDefault true;
        extraModules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Extra PulseAudio modules to load";
        };
      };
      alsa = {
        enable = lib.mkEnableOption "Enable ALSA audio";
        support32Bit = lib.mkDefault true;
        extraConfig = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Extra ALSA configuration";
        };
      };
    };

    config = let
      cfg = config.hardware.audio;
    in lib.mkIf cfg.enable {
      # PipeWire configuration
      services.pipewire = lib.mkIf (cfg.type == "pipewire" || cfg.pipewire.enable) {
        enable = true;
        alsa.enable = cfg.pipewire.alsa.enable;
        alsa.support32Bit = cfg.pipewire.alsa.support32Bit;
        pulse.enable = cfg.pipewire.pulse.enable;
        jack.enable = cfg.pipewire.jack.enable;
        bluetooth.enable = cfg.pipewire.bluetooth.enable;
      };

      # PulseAudio configuration
      services.pulseaudio = lib.mkIf (cfg.type == "pulseaudio" || cfg.pulseaudio.enable) {
        enable = true;
        support32Bit = cfg.pulseaudio.support32Bit;
        extraModules = cfg.pulseaudio.extraModules;
      };

      # ALSA configuration
      sound.enable = lib.mkIf (cfg.type == "alsa" || cfg.alsa.enable) true;
      hardware.pulseaudio.support32Bit = cfg.alsa.support32Bit;

      # Security for audio
      security.rtkit.enable = true;
    };
  };

  # Storage configurations
  storage = { config, lib, pkgs, ... }: {
    options.hardware.storage = {
      enable = lib.mkEnableOption "Enable storage support";
      zfs = {
        enable = lib.mkEnableOption "Enable ZFS support";
        autoScrub = lib.mkDefault true;
        autoSnapshot = lib.mkDefault true;
        pools = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "ZFS pools to manage";
        };
      };
      raid = {
        enable = lib.mkEnableOption "Enable RAID support";
        type = lib.mkOption {
          type = lib.types.enum [ "mdadm" "btrfs" "zfs" ];
          default = "mdadm";
          description = "RAID type to use";
        };
        devices = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "RAID devices";
        };
      };
      ssd = {
        enable = lib.mkEnableOption "Enable SSD optimizations";
        trim = lib.mkDefault true;
        noatime = lib.mkDefault true;
        discard = lib.mkDefault false;
      };
    };

    config = let
      cfg = config.hardware.storage;
    in lib.mkIf cfg.enable {
      # ZFS configuration
      boot.supportedFilesystems = lib.mkIf cfg.zfs.enable [ "zfs" ];
      services.zfs = lib.mkIf cfg.zfs.enable {
        autoScrub.enable = cfg.zfs.autoScrub;
        autoSnapshot.enable = cfg.zfs.autoSnapshot;
      };

      # RAID configuration
      boot.initrd.availableKernelModules = lib.mkIf cfg.raid.enable [ "raid0" "raid1" "raid10" "raid456" ];

      # SSD optimizations
      fileSystems = lib.mkIf cfg.ssd.enable (lib.mapAttrs' (name: value: lib.nameValuePair name (value // {
        options = (value.options or []) ++ (lib.optionals cfg.ssd.noatime [ "noatime" ]) ++ (lib.optionals cfg.ssd.discard [ "discard" ]);
      })) config.fileSystems);

      # TRIM support
      services.fstrim.enable = cfg.ssd.trim;
    };
  };

  # Network configurations
  network = { config, lib, pkgs, ... }: {
    options.hardware.network = {
      enable = lib.mkEnableOption "Enable network hardware support";
      wifi = {
        enable = lib.mkEnableOption "Enable WiFi support";
        firmware = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "WiFi firmware packages";
        };
      };
      bluetooth = {
        enable = lib.mkEnableOption "Enable Bluetooth support";
        powerOnBoot = lib.mkDefault true;
        settings = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = "Bluetooth configuration";
        };
      };
      ethernet = {
        enable = lib.mkEnableOption "Enable Ethernet support";
        wakeOnLan = lib.mkDefault false;
      };
    };

    config = let
      cfg = config.hardware.network;
    in lib.mkIf cfg.enable {
      # WiFi configuration
      hardware.wirelessRegulatoryDatabase = lib.mkIf cfg.wifi.enable true;
      hardware.firmware = lib.mkIf cfg.wifi.enable (with pkgs; [
        linux-firmware
        wireless-regdb
      ] ++ cfg.wifi.firmware);

      # Bluetooth configuration
      hardware.bluetooth = lib.mkIf cfg.bluetooth.enable {
        enable = true;
        powerOnBoot = cfg.bluetooth.powerOnBoot;
        settings = cfg.bluetooth.settings;
      };

      # Ethernet configuration
      networking.interfaces = lib.mkIf cfg.ethernet.enable (lib.mapAttrs' (name: value: lib.nameValuePair name (value // {
        wakeOnLan = lib.mkIf cfg.ethernet.wakeOnLan {
          enable = true;
        };
      })) config.networking.interfaces);
    };
  };

  # Input device configurations
  input = { config, lib, pkgs, ... }: {
    options.hardware.input = {
      enable = lib.mkEnableOption "Enable input device support";
      keyboard = {
        enable = lib.mkEnableOption "Enable keyboard support";
        layout = lib.mkOption {
          type = lib.types.str;
          default = "us";
          description = "Keyboard layout";
        };
        variant = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Keyboard variant";
        };
      };
      mouse = {
        enable = lib.mkEnableOption "Enable mouse support";
        accelProfile = lib.mkOption {
          type = lib.types.enum [ "flat" "adaptive" ];
          default = "adaptive";
          description = "Mouse acceleration profile";
        };
      };
      touchpad = {
        enable = lib.mkEnableOption "Enable touchpad support";
        naturalScrolling = lib.mkDefault true;
        tapToClick = lib.mkDefault true;
        twoFingerScroll = lib.mkDefault true;
      };
    };

    config = let
      cfg = config.hardware.input;
    in lib.mkIf cfg.enable {
      # Keyboard configuration
      services.xserver = lib.mkIf cfg.keyboard.enable {
        layout = cfg.keyboard.layout;
        xkbVariant = cfg.keyboard.variant;
      };

      # Mouse configuration
      services.xserver = lib.mkIf cfg.mouse.enable {
        libinput.mouse.accelProfile = cfg.mouse.accelProfile;
      };

      # Touchpad configuration
      services.xserver = lib.mkIf cfg.touchpad.enable {
        libinput.touchpad = {
          naturalScrolling = cfg.touchpad.naturalScrolling;
          tapToClick = cfg.touchpad.tapToClick;
          scrollMethod = lib.mkIf cfg.touchpad.twoFingerScroll "twofinger";
        };
      };
    };
  };

in {
  # Export all hardware modules
  inherit gpu audio storage network input;

  # Combined hardware configuration
  all = { config, lib, pkgs, ... }: {
    imports = [
      (gpu { inherit config lib pkgs; })
      (audio { inherit config lib pkgs; })
      (storage { inherit config lib pkgs; })
      (network { inherit config lib pkgs; })
      (input { inherit config lib pkgs; })
    ];
  };
}
