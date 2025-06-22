{ pkgs, helpers, config, ... }:
let
  inherit (helpers) isLinux createShellApp readScript;
  linux = [ "x86_64-linux" "aarch64-linux" ];
in
{
  vzdump-backup = if isLinux pkgs.system then pkgs.symlinkJoin {
    name = "vzdump-backup";
    paths = [ (pkgs.writeScriptBin "vzdump-backup" ''
      #!${pkgs.nushell}/bin/nu
      ${readScript "scripts/linux/vzdump-backup.nu"}
    '') ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/vzdump-backup \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.proxmox-backup-client
          pkgs.qemu
          pkgs.lxc
          pkgs.bash
          pkgs.coreutils
          pkgs.gawk
        ]}
    '';
  } else null;

  zfs-snapshot = if isLinux pkgs.system then pkgs.symlinkJoin {
    name = "zfs-snapshot";
    paths = [ (pkgs.writeScriptBin "zfs-snapshot" ''
      #!${pkgs.nushell}/bin/nu
      ${readScript "scripts/linux/zfs-snapshot.nu"}
    '') ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zfs-snapshot \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.zfs
          pkgs.bash
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gawk
          pkgs.gnused
          pkgs.gnutar
        ]}
    '';
  } else null;

  nixos-flake-update = if isLinux pkgs.system then pkgs.symlinkJoin {
    name = "nixos-flake-update";
    paths = [ (pkgs.writeScriptBin "nixos-flake-update" ''
      #!${pkgs.nushell}/bin/nu
      ${readScript "scripts/linux/nixos-flake-update.nu"}
    '') ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nixos-flake-update \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.nix
          pkgs.bash
          pkgs.coreutils
        ]}
    '';
  } else null;

  install = if isLinux pkgs.system then pkgs.symlinkJoin {
    name = "nix-mox-install";
    paths = [ (pkgs.writeScriptBin "nix-mox-install" ''
      #!${pkgs.nushell}/bin/nu
      ${readScript "scripts/linux/install.nu"}
    '') ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nix-mox-install \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
        ]}
    '';
  } else null;

  uninstall = if isLinux pkgs.system then pkgs.symlinkJoin {
    name = "nix-mox-uninstall";
    paths = [ (pkgs.writeScriptBin "nix-mox-uninstall" ''
      #!${pkgs.nushell}/bin/nu
      ${readScript "scripts/linux/uninstall.nu"}
    '') ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nix-mox-uninstall \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
        ]}
    '';
  } else null;

  proxmox-update = if isLinux pkgs.system then pkgs.symlinkJoin {
    name = "proxmox-update";
    paths = [ (pkgs.writeScriptBin "proxmox-update" ''
      #!${pkgs.nushell}/bin/nu
      ${readScript "scripts/linux/proxmox-update.nu"}
    '') ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/proxmox-update \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
        ]}
    '';
  } else null;

  remote-builder-setup = if isLinux pkgs.system then pkgs.symlinkJoin {
    name = "remote-builder-setup";
    paths = [ (pkgs.writeScriptBin "remote-builder-setup" ''
      #!${pkgs.bash}/bin/bash
      ${readScript "scripts/setup-remote-builder.sh"}
    '') ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/remote-builder-setup \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
          pkgs.openssh
          pkgs.curl
          pkgs.gnugrep
          pkgs.gnused
        ]}
    '';
  } else null;

  test-remote-builder = if isLinux pkgs.system then pkgs.symlinkJoin {
    name = "test-remote-builder";
    paths = [ (pkgs.writeScriptBin "test-remote-builder" ''
      #!${pkgs.bash}/bin/bash
      ${readScript "scripts/test-remote-builder.sh"}
    '') ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/test-remote-builder \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
          pkgs.openssh
          pkgs.nix
          pkgs.gnugrep
          pkgs.gnused
        ]}
    '';
  } else null;
}
