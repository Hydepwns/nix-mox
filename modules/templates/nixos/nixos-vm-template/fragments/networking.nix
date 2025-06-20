{ config, pkgs, inputs, ... }:
{
  # Network interface configuration
  networking.interfaces.eth0.useDHCP = true;

  # For a static IP example, comment out the above and use:
  # networking.interfaces.eth0.ipv4.addresses = [{
  #   address = "192.168.100.10";
  #   prefixLength = 24;
  # }];
  # networking.defaultGateway = "192.168.100.1";
  # networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
}
