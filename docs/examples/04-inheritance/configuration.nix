# examples/04-inheritance/configuration.nix
{
  services.nix-mox.templates = {
    enable = true;
    templates = [ "secure-web-server" ];
    customOptions = {
      # The secure-web-server template inherits from web-server,
      # so we can still customize web-server options.
      web-server = {
        serverType = "nginx";
        virtualHosts = [
          {
            name = "secure-site";
            domain = "secure.example.com";
            root = "/var/www/secure";
          }
        ];
      };
      # We can also override the defaults from the child template.
      # In this case, enableSSL is already true in secure-web-server.
      secure-web-server = {
        enableSSL = true;
      };
    };
  };
}
