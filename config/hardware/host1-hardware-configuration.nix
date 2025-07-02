# ============================================================================
# HOST1 HARDWARE CONFIGURATION
# ============================================================================
# Desktop hardware configuration for host1
# ============================================================================

{ config, lib, pkgs, ... }:

{
  # Basic hardware configuration
  imports = [
    # Add any specific hardware imports here
    # ./cpu.nix
    # ./gpu.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce true;
      efi.canTouchEfiVariables = true;
    };

    # Kernel modules
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  # Hardware-specific settings
  hardware = {
    # CPU
    cpu.intel.updateMicrocode = true;

    # Bluetooth
    bluetooth.enable = true;

    # Firmware
    firmware = with pkgs; [
      linux-firmware
      intel-media-driver
    ];
  };

  # Audio services
  services = {
    pulseaudio = {
      enable = false;
      support32Bit = true;
    };
  };

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Swap
  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  # Network
  networking = {
    hostName = "host1";
    useDHCP = lib.mkForce true;
    interfaces.enp0s3.useDHCP = true;
  };

  # Time zone
  time.timeZone = lib.mkForce "America/New_York";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
}
