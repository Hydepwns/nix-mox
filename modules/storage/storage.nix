{ config, lib, pkgs, ... }:

{
  # Import all storage fragments
  imports = [
    ./fragments/base.nix
    ./fragments/zfs.nix
    ./fragments/backup.nix
    ./fragments/monitoring.nix
  ];
}
