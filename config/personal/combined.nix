# Combined Personal Configuration
# Imports both user configuration and personal projects
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hydepwns.nix
    ./projects.nix
  ];
}