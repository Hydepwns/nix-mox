{ config, pkgs, inputs, ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.docker = {
    enable = true;
    enableOnBoot = true;
  };
}
