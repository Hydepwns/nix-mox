# examples/03-composition/configuration.nix
{
  services.nix-mox.templates = {
    enable = true;
    templates = [ "web-app-stack" ];
    customOptions = {
      web-server = {
        serverType = "nginx";
        enableSSL = true;
      };
      database-management = {
        dbType = "postgresql";
        enableBackups = true;
      };
    };
  };
} 