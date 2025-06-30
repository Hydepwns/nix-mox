# Hardware-specific Configuration
# Customize this file with your hardware settings
{ config, pkgs, ... }:
let
  lib = pkgs.lib;
in
{
  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Kernel configuration
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Kernel modules (customize based on your hardware)
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ]; # Change to kvm-amd for AMD
    extraModulePackages = [ ];
  };

  # Graphics configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA drivers (uncomment if you have NVIDIA GPU)
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  # AMD drivers (uncomment if you have AMD GPU)
  # services.xserver.videoDrivers = [ "amdgpu" ];

  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  # hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  # File systems (customize based on your setup)
  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/YOUR-ROOT-UUID";
  #   fsType = "ext4";
  # };

  # fileSystems."/boot" = {
  #   device = "/dev/disk/by-uuid/YOUR-BOOT-UUID";
  #   fsType = "vfat";
  #   options = [ "fmask=0077" "dmask=0077" ];
  # };

  # swapDevices = [ ];

  # Platform configuration
  nixpkgs.hostPlatform = "x86_64-linux"; # Change for your platform
}
