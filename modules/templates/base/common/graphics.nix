{ config, lib, pkgs, ... }:
{
  # Unified graphics defaults
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Default to modesetting/iGPU; templates can enable NVIDIA block below
  services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];

  # Optional NVIDIA configuration (enable in template/profile as needed)
  # Example override in a host/template:
  # services.xserver.videoDrivers = [ "nvidia" "modesetting" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  #   # PRIME (set your bus IDs from lspci)
  #   # prime = {
  #   #   intelBusId = "PCI:0:2:0";
  #   #   nvidiaBusId = "PCI:1:0:0";
  #   #   sync.enable = true; # or offload.enable = true;
  #   # };
  # };

  # If NVIDIA is selected above, blacklist nouveau to avoid conflicts
  boot.blacklistedKernelModules = lib.mkIf (lib.elem "nvidia" config.services.xserver.videoDrivers) [ "nouveau" ];

  # Conservative kernel params; avoid forcing vendor-specific toggles by default
  boot.kernelParams = lib.mkDefault [ "nvidia-drm.modeset=1" ];
}
