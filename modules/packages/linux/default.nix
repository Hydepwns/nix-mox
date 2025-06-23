{ pkgs, helpers, config, ... }:
let
  inherit (helpers) isLinux createShellApp readScript;
  linux = [ "x86_64-linux" "aarch64-linux" ];

  # Check if we should build heavy packages (disable in CI or when explicitly disabled)
  shouldBuildHeavyPackages =
    let
      ci = builtins.getEnv "CI" == "true" || builtins.getEnv "CI" == "1";
      disableHeavy = builtins.getEnv "DISABLE_HEAVY_PACKAGES" == "true" || builtins.getEnv "DISABLE_HEAVY_PACKAGES" == "1";
    in
    !ci && !disableHeavy;

  # Helper function to safely get packages that might not be available on all architectures
  safeGetPkg = pkgName: pkgs.${pkgName} or null;

  # Check if we're building for the correct architecture
  isCorrectArch = system: builtins.elem system linux;

  # Get architecture-specific dependencies
  getArchDeps = system:
    let
      # Common dependencies available on all Linux architectures
      commonDeps = [
        pkgs.bash
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.gnused
        pkgs.gnutar
      ];

      # Architecture-specific dependencies - be more conservative
      archSpecificDeps =
        if system == "x86_64-linux" then [
          # Only include packages that are definitely available
          (safeGetPkg "qemu")
          (safeGetPkg "zfs")
          # Skip proxmox-backup-client and lxc if they cause issues
        ] else if system == "aarch64-linux" then [
          # For aarch64, be even more conservative
          (safeGetPkg "zfs")
          # Skip qemu and lxc on aarch64 if they cause build issues
        ] else [ ];

      # Filter out null values
      filteredDeps = builtins.filter (pkg: pkg != null) archSpecificDeps;
    in
    commonDeps ++ filteredDeps;

  # Create a package with proper architecture checking
  createLinuxPackage = name: scriptPath: deps:
    if !(isCorrectArch pkgs.system) then
      throw "Package '${name}' is only available on Linux systems (x86_64-linux, aarch64-linux), but you're building for ${pkgs.system}"
    else if !(isLinux pkgs.system) then
      null
    else
      let
        # Filter out any null dependencies that might have been passed
        validDeps = builtins.filter (pkg: pkg != null) deps;
      in
      pkgs.symlinkJoin {
        inherit name;
        paths = [
          (pkgs.writeScriptBin name ''
            #!${pkgs.nushell}/bin/nu
            ${readScript scriptPath}
          '')
        ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/${name} \
            --prefix PATH : ${pkgs.lib.makeBinPath validDeps}
        '';
      };

  # Base packages (always available)
  basePackages = {
    # Lightweight packages (always available)
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
  };

  # Heavy packages (conditional based on environment)
  heavyPackages =
    if shouldBuildHeavyPackages then {
      vzdump-backup = createLinuxPackage "vzdump-backup" "scripts/linux/vzdump-backup.nu" (getArchDeps pkgs.system);
      zfs-snapshot = createLinuxPackage "zfs-snapshot" "scripts/linux/zfs-snapshot.nu" (getArchDeps pkgs.system);
    } else { };

in
basePackages // heavyPackages
