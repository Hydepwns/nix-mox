{ config, pkgs, inputs, ... }:
{
  # NVIDIA and OpenGL Support (updated for newer NixOS)
  # Uncomment if you need graphics support in your VM
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.graphics.enable = true;
  # hardware.graphics.driSupport = true;
  # hardware.graphics.enable32Bit = true;
  # hardware.pulseaudio.support32Bit = true;
}
