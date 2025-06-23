# examples/05-variables/configuration.nix
{
  services.nix-mox.templates = {
    enable = true;
    templates = [ "web-server" ];
    templateVariables = {
      admin_user = "site-admin";
      domain = "mycoolsite.com";
    };
  };
}
