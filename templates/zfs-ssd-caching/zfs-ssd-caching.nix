{ config, pkgs, lib, ... }:
{
  # Ensure the rpool is imported before running this service
  boot.zfs.extraPools = [ "rpool" ];

  systemd.services.zfs-ssd-caching = {
    description = "Auto-configure ZFS SSD caching (L2ARC)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      #!/bin/sh
      # Detect all NVMe SSDs (customize the glob as needed)
      for dev in /dev/nvme*n1; do
        # Only add if not already present in the pool
        if ! zpool status rpool | grep -q "$dev"; then
          echo "Adding $dev as L2ARC cache to rpool..."
          zpool add rpool cache $dev || true
        fi
      done
    '';
    # Only run if rpool is imported
    serviceConfig.Requires = [ "zfs-import-rpool.service" ];
    serviceConfig.After = [ "zfs-import-rpool.service" ];
  };

  # To use as special vdevs instead, change the zpool add line to:
  # zpool add rpool special mirror $dev ...
} 