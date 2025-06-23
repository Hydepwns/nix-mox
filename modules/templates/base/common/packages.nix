{ config, pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop
    firefox
    kitty
    alacritty
    inputs.nix-mox.packages.${pkgs.system}.proxmox-update
    inputs.nix-mox.packages.${pkgs.system}.vzdump-backup
    inputs.nix-mox.packages.${pkgs.system}.zfs-snapshot
    inputs.nix-mox.packages.${pkgs.system}.nixos-flake-update
    vscode
    docker
    docker-compose
  ];
}
