{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/base.nix
    ../fragments/ci-runner.nix
  ];

  networking.hostName = "ci-runner-vm";
}
