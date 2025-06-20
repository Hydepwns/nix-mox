{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/base.nix
    ../fragments/database.nix
  ];

  networking.hostName = "database-vm";

  # Uncomment and configure your preferred database
  # services.postgresql.enable = true;
  # services.postgresql.package = pkgs.postgresql_15;
}
