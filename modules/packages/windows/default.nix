{ pkgs, helpers, config, ... }:
let
  inherit (helpers) readScript;
  windows = [ "x86_64-windows" "aarch64-windows" ];

  # Helper function to safely get packages
  safeGetPkg = pkgName: pkgs.${pkgName} or null;

  # Check if we're building for the correct architecture
  isCorrectArch = system: builtins.elem system windows;

  # Get architecture-specific dependencies
  getArchDeps = system: let
    commonDeps = [
      pkgs.bash
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.curl
      pkgs.jq
    ];
    archSpecificDeps = if system == "x86_64-windows" then [
      (safeGetPkg "powershell")
      (safeGetPkg "python3")
    ] else if system == "aarch64-windows" then [
      (safeGetPkg "powershell")
    ] else [];
    filteredDeps = builtins.filter (pkg: pkg != null) archSpecificDeps;
  in commonDeps ++ filteredDeps;

  # Create a package with proper architecture checking
  createWindowsPackage = name: scriptPath: deps:
    if !(isCorrectArch pkgs.system) then
      throw "Package '${name}' is only available on Windows systems (x86_64-windows, aarch64-windows), but you're building for ${pkgs.system}"
    else if !(pkgs.stdenv.isWindows or false) then
      null
    else
      pkgs.symlinkJoin {
        inherit name;
        paths = [ (pkgs.writeScriptBin name ''
          #!${pkgs.bash}/bin/bash
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
  # Windows-specific install script
  install = createWindowsPackage "nix-mox-install" "scripts/windows/install.ps1" (getArchDeps pkgs.system);

  # Windows-specific uninstall script
  uninstall = createWindowsPackage "nix-mox-uninstall" "scripts/windows/uninstall.ps1" [
    pkgs.bash
    pkgs.coreutils
  ];

  # Windows gaming setup script
  install-steam-rust = createWindowsPackage "install-steam-rust" "scripts/windows/install-steam-rust.nu" [
    pkgs.bash
    pkgs.coreutils
    pkgs.curl
  ];

  windows-automation-assets-sources = if isDarwin pkgs.system then pkgs.stdenv.mkDerivation {
    name = "windows-automation-assets-sources";
    src = ./../scripts/windows;
    installPhase = ''
      mkdir -p $out
      cp $src/install-steam-rust.nu $out/
      cp $src/run-steam-rust.bat $out/
      cp $src/InstallSteamRust.xml $out/
    '';
    meta = {
      description = "Source files for Windows automation (Steam, Rust NuShell script, .bat, .xml). Requires Nushell on the Windows host.";
    };
  } else null;
}
