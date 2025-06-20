{ config, lib, pkgs, ... }:

{
  # Import all cache server fragments
  imports = [
    ./fragments/base.nix
    ./fragments/redis.nix
    ./fragments/memcached.nix
    ./fragments/monitoring.nix
    ./fragments/backup.nix
  ];
}
