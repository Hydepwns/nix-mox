{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../../error-handling.nix { inherit config lib pkgs; };

  # Template configuration
  cfg = config.services.nix-mox.cache-server;

  # Cache server types
  cacheTypes = {
    redis = {
      package = pkgs.redis;
      service = "redis";
      configDir = "/etc/redis";
      logDir = "/var/log/redis";
      defaultPort = 6379;
      metricsPort = 9121;
    };
    memcached = {
      package = pkgs.memcached;
      service = "memcached";
      configDir = "/etc/memcached";
      logDir = "/var/log/memcached";
      defaultPort = 11211;
      metricsPort = 9150;
    };
  };

  # Validation functions
  validateConfig = { cacheType, ... }@config:
    let
      validCacheTypes = builtins.attrNames cacheTypes;
    in
    if !builtins.elem cacheType validCacheTypes then
      errorHandling.handleError 1 "Invalid cache server type: ${cacheType}. Valid types: ${lib.concatStringsSep ", " validCacheTypes}"
    else
      true;
in
{
  options.services.nix-mox.cache-server = {
    enable = lib.mkEnableOption "Enable cache server template";
    cacheType = lib.mkOption {
      type = lib.types.enum (builtins.attrNames cacheTypes);
      default = "redis";
      description = "Type of cache server to use";
    };
    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the cache server to";
    };
    maxMemory = lib.mkOption {
      type = lib.types.int;
      default = 1024;
      description = "Maximum memory usage in MB";
    };
    maxConnections = lib.mkOption {
      type = lib.types.int;
      default = 1024;
      description = "Maximum number of connections";
    };
    password = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Password for authentication";
    };
    customConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Custom cache server configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate configuration
    assertions = [
      {
        assertion = validateConfig cfg;
        message = "Invalid cache server configuration";
      }
    ];

    # Add cache server package
    environment.systemPackages = with pkgs; [
      cacheTypes.${cfg.cacheType}.package
    ];
  };
}
