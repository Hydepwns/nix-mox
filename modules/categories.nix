{
  core = {
    description = "Core functionality and base modules";
    modules = [ "nix-mox" ];
  };

  system = {
    description = "System-level configurations";
    modules = [ "networking" "hardware" "boot" "users" ];
  };

  services = {
    description = "Service-specific modules";
    modules = [ "infisical" "tailscale" ];
  };

  storage = {
    description = "Storage-related modules";
    modules = [ "zfs" ];
  };

  security = {
    description = "Security-related modules";
    modules = [ ];
  };

  monitoring = {
    description = "Monitoring and observability modules";
    modules = [ ];
  };

  gaming = {
    description = "Gaming-specific modules";
    modules = [ ];
  };

  packages = {
    description = "Package-specific modules";
    modules = [ "development" "multimedia" "productivity" "system" "linux" "windows" ];
  };

  templates = {
    description = "Template configurations";
    modules = [ "templates" "services" "infrastructure" "platforms" ];
  };
}