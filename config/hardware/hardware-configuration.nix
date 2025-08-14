# Hardware Configuration Template
# This file serves as a template for hardware configuration.
# The actual hardware configuration should be generated using:
# sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration.nix

{ config, lib, pkgs, modulesPath, ... }:

let
  # Prefer host system hardware config if present to avoid mismatched disk IDs
  hostHardwarePath = /etc/nixos/hardware-configuration.nix;
  useHostHardware = builtins.pathExists hostHardwarePath;
  # Import the actual hardware configuration from repo
  actualHardware = import ./hardware-configuration-actual.nix { inherit config lib pkgs modulesPath; };
  hasRepoActual = builtins.pathExists ./hardware-configuration-actual.nix;
 in

# Resolution order:
# 1) Host /etc/nixos/hardware-configuration.nix if it exists
# 2) Repo actual hardware config if provided
# 3) Basic template
if useHostHardware then
  import hostHardwarePath { inherit config lib pkgs modulesPath; }
else if hasRepoActual then
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
  # Note: UUID is more stable than partuuid for filesystem identification
  # partuuid can change when partition table is modified, while UUID remains constant
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
