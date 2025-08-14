# Combined Personal Configuration
# Imports both user configuration and personal projects
{ config, pkgs, lib, ... }:

let
  includePersonal = builtins.getEnv "NIXMOX_INCLUDE_PERSONAL" == "1";
 in
{
  imports = if includePersonal then [
    ./hydepwns.nix
    ./projects.nix
  ] else [ ];
}