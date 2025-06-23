{ pkgs, helpers, config, ... }:
let
  inherit (helpers) readScript;

  # macOS systems
  macos = [ "x86_64-darwin" "aarch64-darwin" ];

  # Helper function to safely get packages that might not be available
  safeGetPkg = pkgName: pkgs.${pkgName} or null;

  # Check if we're building for the correct architecture
  isCorrectArch = system: builtins.elem system macos;

  # Get architecture-specific dependencies
  getArchDeps = system:
    let
      # Common dependencies available on all macOS architectures
      commonDeps = [
        pkgs.bash
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.gnused
        pkgs.gnutar
        pkgs.curl
        pkgs.jq
      ];

      # Architecture-specific dependencies
      archSpecificDeps =
        if system == "x86_64-darwin" then [
          # Intel Mac specific packages
          (safeGetPkg "homebrew")
          (safeGetPkg "mas")
        ] else if system == "aarch64-darwin" then [
          # Apple Silicon specific packages
          (safeGetPkg "homebrew")
          (safeGetPkg "mas")
          (safeGetPkg "cocoapods")
        ] else [ ];

      # Filter out null values
      filteredDeps = builtins.filter (pkg: pkg != null) archSpecificDeps;
    in
    commonDeps ++ filteredDeps;

  # Create a package with proper architecture checking
  createMacOSPackage = name: scriptPath: deps:
    if !(isCorrectArch pkgs.system) then
      throw "Package '${name}' is only available on macOS systems (x86_64-darwin, aarch64-darwin), but you're building for ${pkgs.system}"
    else if !(pkgs.stdenv.isDarwin) then
      null
    else
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
            --prefix PATH : ${pkgs.lib.makeBinPath deps} \
            --set MACOSX_DEPLOYMENT_TARGET 11.0 \
            --set SDKROOT ${pkgs.darwin.apple_sdk.MacOSX-SDK}/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
        '';
      };
in
{
  # macOS-specific installation script
  install = createMacOSPackage "nix-mox-install" "scripts/macos/install.nu" (getArchDeps pkgs.system);

  # macOS-specific uninstallation script
  uninstall = createMacOSPackage "nix-mox-uninstall" "scripts/macos/uninstall.nu" [
    pkgs.bash
    pkgs.coreutils
  ];

  # Homebrew management script
  homebrew-setup = createMacOSPackage "homebrew-setup" "scripts/macos/homebrew-setup.nu" [
    pkgs.bash
    pkgs.coreutils
    pkgs.curl
    pkgs.jq
  ];

  # macOS system maintenance script
  macos-maintenance = createMacOSPackage "macos-maintenance" "scripts/macos/macos-maintenance.nu" [
    pkgs.bash
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
  ];

  # Xcode command line tools setup
  xcode-setup = createMacOSPackage "xcode-setup" "scripts/macos/xcode-setup.nu" [
    pkgs.bash
    pkgs.coreutils
    pkgs.curl
  ];

  # macOS security audit script
  security-audit = createMacOSPackage "security-audit" "scripts/macos/security-audit.nu" [
    pkgs.bash
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.jq
  ];
}
