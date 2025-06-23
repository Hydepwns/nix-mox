{ config, pkgs, ... }:
{
  virtualisation.oci-containers.containers.nginx = {
    image = "nginx:latest";
    ports = [ "8080:80" ];
    autoStart = true;
  };
}
