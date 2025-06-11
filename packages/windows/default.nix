{ pkgs, helpers, ... }:
let
  inherit (helpers) createTextFile readScript;
in
{
  install-steam-rust = createTextFile {
    name = "install-steam-rust.nu";
    destination = "/bin/install-steam-rust.nu";
    text = ''
      #!${pkgs.nushell}/bin/nu
      ${readScript ./scripts/windows/install-steam-rust.nu}
    '';
    executable = true;
  };

  windows-automation-assets-sources = pkgs.stdenv.mkDerivation {
    name = "windows-automation-assets-sources";
    src = ./scripts/windows;
    installPhase = ''
      mkdir -p $out
      cp $src/install-steam-rust.nu $out/
      cp $src/run-steam-rust.bat $out/
      cp $src/InstallSteamRust.xml $out/
    '';
    meta = {
      description = "Source files for Windows automation (Steam, Rust NuShell script, .bat, .xml). Requires Nushell on the Windows host.";
    };
  };
} 