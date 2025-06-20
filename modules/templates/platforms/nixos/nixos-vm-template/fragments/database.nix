{ config, pkgs, inputs, ... }:
{
  # Database Server Configuration

  # PostgreSQL
  # services.postgresql.enable = true;
  # services.postgresql.package = pkgs.postgresql_15;

  # MySQL/MariaDB
  # services.mysql.enable = true;
  # services.mysql.package = pkgs.mysql80;

  # Redis
  # services.redis.enable = true;

  # MongoDB
  # services.mongodb.enable = true;

  # Add database ports to firewall (uncomment as needed)
  # networking.firewall.allowedTCPPorts = config.networking.firewall.allowedTCPPorts ++ [
  #   5432  # PostgreSQL
  #   3306  # MySQL
  #   6379  # Redis
  #   27017 # MongoDB
  # ];
}
