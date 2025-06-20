{ config, pkgs, inputs, ... }:
{
  # Example Hardware Configuration
  # Disk and filesystem setup
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  # Uncomment and adjust for additional disks or mount points
  # fileSystems."/data" = {
  #   device = "/dev/vdb1";
  #   fsType = "ext4";
  # };

  # Example swap device
  swapDevices = [
    { device = "/dev/vda2"; }
  ];
}
