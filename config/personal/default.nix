# Personal Configuration Aggregator
# This file manages personal settings based on environment
{ config, pkgs, ... }:
let
  # Environment detection
  isProduction = builtins.getEnv "NIXMOX_ENV" == "production";
  isDevelopment = builtins.getEnv "NIXMOX_ENV" == "development";
  isPersonal = builtins.getEnv "NIXMOX_ENV" == "personal" || builtins.getEnv "NIXMOX_ENV" == "";

  # Check if personal files exist
  hasUserConfig = builtins.pathExists ./user.nix;
  hasHardwareConfig = builtins.pathExists ./hardware.nix;
  hasSecretsConfig = builtins.pathExists ./secrets.nix;
  hasLocalConfig = builtins.pathExists ./local.nix;
in
{
  imports =
    (if hasUserConfig then [ ./user.nix ] else [ ]) ++
    (if hasHardwareConfig then [ ./hardware.nix ] else [ ]) ++
    (if isPersonal && hasSecretsConfig then [ ./secrets.nix ] else [ ]) ++
    (if hasLocalConfig then [ ./local.nix ] else [ ]);

  # Default personal settings if no user config exists
  personal = {
    username = builtins.getEnv "NIXMOX_USERNAME" or "user";
    email = builtins.getEnv "NIXMOX_EMAIL" or "user@example.com";
    timezone = builtins.getEnv "NIXMOX_TIMEZONE" or "UTC";
    hostname = builtins.getEnv "NIXMOX_HOSTNAME" or "nixos";
    gitUsername = builtins.getEnv "NIXMOX_GIT_USERNAME" or "user";
    gitEmail = builtins.getEnv "NIXMOX_GIT_EMAIL" or "user@example.com";
  };
}
