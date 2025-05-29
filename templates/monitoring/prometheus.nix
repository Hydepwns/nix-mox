{ config, pkgs, ... }:
{
  services.prometheus = {
    enable = true;
    configFile = ./prometheus.yml;
    listenAddress = "0.0.0.0";
    port = 9090;
    # Add extra scrape configs or alerting rules as needed
  };

  # Optionally, open the Prometheus port in the firewall
  networking.firewall.allowedTCPPorts = [ 9090 ];
} 