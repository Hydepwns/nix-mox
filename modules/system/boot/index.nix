{ pkgs, config, lib, ... }:

let
  # Systemd-boot configuration (default)
  systemd-boot = { config, lib, pkgs, ... }: {
    options.boot.loader = {
      systemd-boot = {
        enable = lib.mkEnableOption "Enable systemd-boot";
        configurationLimit = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Number of boot entries to keep";
        };
        editor = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Allow editing boot entries";
        };
        timeout = lib.mkOption {
          type = lib.types.int;
          default = 5;
          description = "Boot timeout in seconds";
        };
      };
      grub = {
        enable = lib.mkEnableOption "Enable GRUB bootloader";
        device = lib.mkOption {
          type = lib.types.str;
          description = "GRUB device (e.g., /dev/sda)";
        };
        useOSProber = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable OS prober for dual boot";
        };
        efiSupport = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable EFI support";
        };
      };
    };

    config =
      let
        cfg = config.boot.loader;
      in
      {
        # Default to systemd-boot
        boot.loader.systemd-boot = lib.mkDefault {
          enable = true;
          configurationLimit = cfg.systemd-boot.configurationLimit;
          editor = cfg.systemd-boot.editor;
          timeout = cfg.systemd-boot.timeout;
        };

        # GRUB configuration (alternative)
        boot.loader.grub = lib.mkIf cfg.grub.enable {
          enable = true;
          device = cfg.grub.device;
          useOSProber = cfg.grub.useOSProber;
          efiSupport = cfg.grub.efiSupport;
        };

        # EFI support
        boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
      };
  };

in
{
  # Export boot modules
  inherit systemd-boot;

  # Default boot configuration
  default = systemd-boot;
}
