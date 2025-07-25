# Hardware Configuration Template
# This file serves as a template for hardware configuration.
# The actual hardware configuration should be generated using:
# sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration.nix

{ config, lib, pkgs, modulesPath, ... }:

let
  # Import the actual hardware configuration
  # This should be generated for your specific hardware
  actualHardware = import ./hardware-configuration-actual.nix { inherit config lib pkgs modulesPath; };
in

# Use the actual hardware configuration if it exists, otherwise use a basic template
if builtins.pathExists ./hardware-configuration-actual.nix then
  actualHardware
else {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Basic hardware configuration template
  # Replace this with your actual hardware configuration

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # File systems - replace with your actual file system configuration
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/YOUR-ROOT-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/YOUR-BOOT-UUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  # Networking
  networking.useDHCP = lib.mkDefault true;

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Boot loader - use systemd-boot for UEFI systems
  boot.loader.systemd-boot.enable = lib.mkForce true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
