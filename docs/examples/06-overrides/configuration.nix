# examples/06-overrides/configuration.nix
{
  services.nix-mox.templates = {
    enable = true;
    templates = [ "web-server" ];
    templateVariables = {
      admin_user = "override-admin";
      domain = "should-not-be-used.com";
    };
    templateOverrides = {
      "web-server" = ./my-web-server-overrides;
    };
  };
}
