{ config, pkgs, inputs, ... }:
{
  # Graphics configuration (updated for newer NixOS)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
