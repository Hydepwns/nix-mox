# ============================================================================
# HOST2 HARDWARE CONFIGURATION
# ============================================================================
# Server hardware configuration for host2
# ============================================================================

{ config, lib, pkgs, ... }:

{
  # Basic hardware configuration
  imports = [
    # Add any specific hardware imports here
    # ./cpu.nix
    # ./network.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
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

    # Firmware
    firmware = with pkgs; [
      linux-firmware
    ];
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

  # Data directory for server applications
  fileSystems."/var/lib" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # Swap
  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  # Network
  networking = {
    hostName = "host2";
    useDHCP = true;
    interfaces.enp0s3.useDHCP = true;

    # Static IP configuration (optional)
    # interfaces.enp0s3 = {
    #   useDHCP = false;
    #   ipv4.addresses = [{
    #     address = "192.168.1.100";
    #     prefixLength = 24;
    #   }];
    # };
    # defaultGateway = "192.168.1.1";
    # nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };

  # Time zone
  time.timeZone = "UTC";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Server-specific optimizations
  boot = {
    kernel.sysctl = {
      # Network optimizations
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";

      # File system optimizations
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
    };
  };
}
