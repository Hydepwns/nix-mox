{ pkgs, helpers, ... }:
let
  inherit (helpers) createTextFile readScript isDarwin;
in
{
  install-steam-rust = if isDarwin pkgs.system then createTextFile {
    name = "install-steam-rust.nu";
    destination = "/bin/install-steam-rust.nu";
    text = ''
      #!${pkgs.nushell}/bin/nu
      ${readScript "scripts/windows/install-steam-rust.nu"}
    '';
    executable = true;
  } else null;

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
