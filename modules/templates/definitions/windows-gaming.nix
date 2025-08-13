{ config, lib, pkgs, ... }:

# Windows gaming template definition
{
  name = "windows-gaming";
  description = "Windows gaming template with Steam and Rust";
  scripts = [
    "install-steam-rust.nu"
    "run-steam-rust.bat"
    "InstallSteamRust.xml"
  ];
  dependencies = [
    "steam"
    "rust"
  ];
  customOptions = {
    steam = {
      installPath = lib.mkOption {
        type = lib.types.str;
        default = "C:\\Program Files (x86)\\Steam";
        description = "Path to install Steam.";
      };
      downloadURL = lib.mkOption {
        type = lib.types.str;
        default = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe";
        description = "URL to download Steam from.";
      };
      silentInstall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install Steam silently.";
      };
    };
    rust = {
      appId = lib.mkOption {
        type = lib.types.str;
        default = "252490";
        description = "Steam AppID for Rust.";
      };
      installPath = lib.mkOption {
        type = lib.types.str;
        default = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Rust";
        description = "Path to install Rust.";
      };
    };
    monitoring = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable monitoring.";
      };
      logPath = lib.mkOption {
        type = lib.types.str;
        default = "C:\\Program Files (x86)\\Steam\\logs";
        description = "Path to store logs.";
      };
    };
  };
} 