{ pkgs, helpers, config, ... }:
let
  inherit (helpers) isLinux createShellApp readScript;
  linux = [ "x86_64-linux" "aarch64-linux" ];

  # Helper function to safely get packages that might not be available on all architectures
  safeGetPkg = pkgName: pkgs.${pkgName} or null;

  # Check if we're building for the correct architecture
  isCorrectArch = system: builtins.elem system linux;

  # Get architecture-specific dependencies
  getArchDeps = system: let
    # Common dependencies available on all Linux architectures
    commonDeps = [
      pkgs.bash
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.gnutar
    ];

    # Architecture-specific dependencies
    archSpecificDeps = if system == "x86_64-linux" then [
      (safeGetPkg "proxmox-backup-client")
      (safeGetPkg "qemu")
      (safeGetPkg "lxc")
      (safeGetPkg "zfs")
    ] else if system == "aarch64-linux" then [
      # For aarch64, use more basic alternatives or skip problematic packages
      (safeGetPkg "qemu")
      (safeGetPkg "lxc")
      (safeGetPkg "zfs")
    ] else [];

    # Filter out null values
    filteredDeps = builtins.filter (pkg: pkg != null) archSpecificDeps;
  in commonDeps ++ filteredDeps;

  # Create a package with proper architecture checking
  createLinuxPackage = name: scriptPath: deps:
    if !(isCorrectArch pkgs.system) then
      throw "Package '${name}' is only available on Linux systems (x86_64-linux, aarch64-linux), but you're building for ${pkgs.system}"
    else if !(isLinux pkgs.system) then
      null
    else
      pkgs.symlinkJoin {
        inherit name;
        paths = [ (pkgs.writeScriptBin name ''
          #!${pkgs.nushell}/bin/nu
          ${readScript scriptPath}
        '') ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/${name} \
            --prefix PATH : ${pkgs.lib.makeBinPath deps}
        '';
      };
in
{
  vzdump-backup = createLinuxPackage "vzdump-backup" "scripts/linux/vzdump-backup.nu" (getArchDeps pkgs.system);

  zfs-snapshot = createLinuxPackage "zfs-snapshot" "scripts/linux/zfs-snapshot.nu" (getArchDeps pkgs.system);

  nixos-flake-update = createLinuxPackage "nixos-flake-update" "scripts/linux/nixos-flake-update.nu" [
    pkgs.nix
    pkgs.bash
    pkgs.coreutils
  ];

  install = createLinuxPackage "nix-mox-install" "scripts/linux/install.nu" [
    pkgs.bash
    pkgs.coreutils
  ];

  uninstall = createLinuxPackage "nix-mox-uninstall" "scripts/linux/uninstall.nu" [
    pkgs.bash
    pkgs.coreutils
  ];

  proxmox-update = createLinuxPackage "proxmox-update" "scripts/linux/proxmox-update.nu" [
    pkgs.bash
    pkgs.coreutils
  ];

  remote-builder-setup = createLinuxPackage "remote-builder-setup" "scripts/setup-remote-builder.sh" [
    pkgs.bash
    pkgs.coreutils
    pkgs.openssh
    pkgs.curl
    pkgs.gnugrep
    pkgs.gnused
  ];

  test-remote-builder = createLinuxPackage "test-remote-builder" "scripts/test-remote-builder.sh" [
    pkgs.bash
    pkgs.coreutils
    pkgs.openssh
    pkgs.nix
    pkgs.gnugrep
    pkgs.gnused
  ];
}
