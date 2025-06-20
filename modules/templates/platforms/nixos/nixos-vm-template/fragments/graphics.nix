{ config, pkgs, inputs, ... }:
{
  # NVIDIA and OpenGL Support
  # Uncomment if you need graphics support in your VM
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.opengl.enable = true;
  # hardware.opengl.driSupport = true;
  # hardware.opengl.driSupport32Bit = true;
  # hardware.pulseaudio.support32Bit = true;
}
