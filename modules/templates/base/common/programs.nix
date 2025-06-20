{ config, pkgs, inputs, ... }:
{
  programs = {
    zsh.enable = true;
    git.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
