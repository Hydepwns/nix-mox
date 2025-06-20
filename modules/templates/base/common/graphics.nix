{ config, pkgs, inputs, ... }:
{
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
}
