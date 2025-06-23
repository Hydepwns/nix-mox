{ config, pkgs, ... }:
{
  imports = [ ./base.nix ];

  networking.hostName = "web-vm";
  services.nginx.enable = true;
  networking.firewall.allowedTCPPorts = config.networking.firewall.allowedTCPPorts ++ [ 80 ];
}
