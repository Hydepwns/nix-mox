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
}
