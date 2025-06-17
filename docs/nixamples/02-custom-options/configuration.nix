# examples/02-custom-options/configuration.nix
{
  services.nix-mox.templates = {
    enable = true;
    templates = [ "web-server" ];
    customOptions = {
      web-server = {
        serverType = "nginx";
        enableSSL = true;
        virtualHosts = [
          {
            name = "example";
            domain = "example.com";
            root = "/var/www/example";
          }
        ];
      };
    };
  };
} 