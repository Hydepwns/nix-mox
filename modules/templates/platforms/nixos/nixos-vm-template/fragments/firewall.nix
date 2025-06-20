{ config, pkgs, inputs, ... }:
{
  # Firewall configuration
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ]; # Allow SSH only by default

  # Example: allow web ports
  # networking.firewall.allowedTCPPorts = [ 22 80 443 ];
}
