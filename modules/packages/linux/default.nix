{ pkgs, helpers, config, ... }:
let
  inherit (helpers) isLinux createShellApp readScript;
  inherit (config.config.meta.platforms) linux;
in
{
  vzdump-backup = if isLinux pkgs.system then createShellApp {
    name = "vzdump-backup";
    runtimeInputs = [
      pkgs.proxmox-backup-client
      pkgs.qemu
      pkgs.lxc
      pkgs.bash
      pkgs.coreutils
      pkgs.gawk
    ];
    text = readScript "scripts/linux/vzdump-backup.nu";
    meta = {
      description = "Backup all Proxmox VMs and containers to specified storage.";
      platforms = linux;
    };
  } else null;

  zfs-snapshot = if isLinux pkgs.system then createShellApp {
    name = "zfs-snapshot";
    runtimeInputs = [
      pkgs.zfs
      pkgs.bash
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gawk
      pkgs.gnused
      pkgs.gnutar
    ];
    text = readScript "scripts/linux/zfs-snapshot.nu";
    meta = {
      description = "Create and prune ZFS snapshots for the specified pool.";
      platforms = linux;
    };
  } else null;

  nixos-flake-update = if isLinux pkgs.system then createShellApp {
    name = "nixos-flake-update";
    runtimeInputs = [ pkgs.nix pkgs.bash pkgs.coreutils ];
    text = readScript "scripts/linux/nixos-flake-update.nu";
    meta = {
      description = "Update flake inputs and rebuild NixOS system.";
      platforms = linux;
    };
  } else null;

  install = if isLinux pkgs.system then pkgs.writeScriptBin "nix-mox-install" ''
    #!${pkgs.bash}/bin/bash
    ${readScript "scripts/linux/install.nu"}
  '' else null;

  uninstall = if isLinux pkgs.system then let
    commonSh = readScript "scripts/linux/_common.nu";
    uninstallSh = readScript "scripts/linux/uninstall.nu";
  in createShellApp {
    name = "nix-mox-uninstall";
    runtimeInputs = [ pkgs.bash pkgs.coreutils ];
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # Write _common.nu to a temp file
      common_sh=$(mktemp)
      cat > "$common_sh" <<'EOF'
      ${commonSh}
      EOF

      # Source common functions
      source "$common_sh"

      # Main uninstall logic
      ${uninstallSh}
    '';
    meta = {
      description = "Legacy/compat uninstall logic for nix-mox scripts.";
      platforms = linux;
    };
  } else null;

  proxmox-update = if isLinux pkgs.system then createShellApp {
    name = "proxmox-update";
    runtimeInputs = [ pkgs.apt pkgs.bash pkgs.coreutils ];
    text = readScript "scripts/linux/proxmox-update.nu";
    meta = {
      description = "Update and upgrade Proxmox host packages safely.";
      platforms = linux;
    };
  } else null;
}
