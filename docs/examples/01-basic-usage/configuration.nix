# examples/01-basic-usage/configuration.nix
{
  services.nix-mox.templates = {
    enable = true;
    templates = [ "web-server" ];
  };
}
