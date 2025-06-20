{ config, pkgs, inputs, ... }:
{
  # Web Server Configuration
  services.nginx.enable = true;

  # Add web ports to firewall
  networking.firewall.allowedTCPPorts = config.networking.firewall.allowedTCPPorts ++ [ 80 443 ];

  # Optional: Enable SSL with Let's Encrypt
  # security.acme.acceptTerms = true;
  # security.acme.defaults.email = "your-email@example.com";
  # services.nginx.virtualHosts."your-domain.com" = {
  #   enableACME = true;
  #   forceSSL = true;
  #   root = "/var/www/your-domain.com";
  # };
}
