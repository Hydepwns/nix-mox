# ZFS SSD Caching Example

This directory explains how to add SSDs as special vdevs or L2ARC to your ZFS pool for improved VM disk performance.

---

For general instructions on using, customizing, and best practices for templates, see [../USAGE.md](../templates/USAGE.md).

## Usage

- Import this module or snippet into your NixOS configuration.
- Adjust the device glob and pool name as needed for your setup.
- On boot, any detected NVMe SSDs not already in the pool will be added as L2ARC cache.
- For special vdevs, change `zpool add rpool cache $dev` to `zpool add rpool special mirror $dev ...` as appropriate.

## Example Commands

### Add a special vdev (metadata/small files)

zpool add rpool special mirror /dev/nvme0n1 /dev/nvme1n1

### Add an L2ARC (read cache)

zpool add rpool cache /dev/nvme2n1

## NixOS Automation Example

The `zfs-ssd-caching.nix` module automates the detection and configuration of SSDs as ZFS special vdevs (for metadata/small files) or L2ARC (read cache) in your NixOS system.

### Example NixOS Module

```nix
{ config, pkgs, lib, ... }:
{
  # Example: Automatically add NVMe SSDs as L2ARC cache to the 'rpool' ZFS pool
  boot.zfs.extraPools = [ "rpool" ];
  systemd.services.zfs-ssd-caching = {
    description = "Auto-configure ZFS SSD caching (L2ARC)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for dev in /dev/nvme*n1; do
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
}
```
