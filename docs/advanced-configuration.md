# Advanced Configuration Guide

This guide covers advanced configuration topics for networking, storage, security, and monitoring in a NixOS and Proxmox environment.

---

## Networking

To improve security and manageability, it's recommended to isolate network traffic using multiple Linux bridges on your Proxmox host.

- **vmbr0**: For general-purpose VMs and containers (e.g., NixOS).
- **vmbr1**: For less trusted systems (e.g., Windows).
- **vmbr2**: For management and out-of-band access.

By assigning VMs to different bridges, you can apply different firewall rules and prevent lateral movement between different security zones.

## Shared Storage

For sharing files between the Proxmox host and a NixOS guest, `virtio-fs` provides a high-performance solution.

In your NixOS configuration (`configuration.nix`):

```nix
# Enables the virtiofsd service on the host and mounts the share in the guest
virtualisation.sharedDirectories = {
  # 'win-share' is an arbitrary name for the share
  win-share = {
    source = "/mnt/host/windows-share"; # Path on the Proxmox host
    target = "/mnt/guest/win-mount";     # Path inside the NixOS VM
  };
};
```

You will also need to configure the corresponding virtiofs device for the VM in Proxmox.

## Security

### Read-only Root Filesystem

For a more secure, stateless system, you can configure your NixOS root filesystem to be read-only. This prevents runtime changes to the system configuration.

```nix
# in your NixOS configuration
fileSystems."/".options = [ "ro" "nosuid" "nodev" ];
```

Changes can only be made by rebuilding the configuration and rebooting.

### Non-root Services

Whenever possible, run system services as dedicated, non-root users to limit their privileges.

```nix
# Example for nginx
users.users.nginx = {
  isSystemUser = true;
  group = "nginx";
};

services.nginx.user = "nginx";
```

### Software Bill of Materials (SBOM)

You can generate an SBOM for any Nix package to audit its dependencies.

```bash
nix store make-content-addressable /nix/store/...-nginx-* --rewrite-outputs > sbom.json
```

## Monitoring & Updates

### Unified Logging

Forward logs from your NixOS instances to a central syslog server for unified monitoring.

```nix
# in your NixOS configuration
services.journald.extraConfig = ''
  ForwardToSyslog=yes
  MaxLevelSyslog=debug
'';
```

### Automatic Upgrades

NixOS can be configured to automatically update itself from a Git repository.

```nix
# in your NixOS configuration
system.autoUpgrade = {
  enable = true;
  # Points to a flake output in a Git repository
  flake = "github:user/nix-config#my-container";
  dates = "daily"; # or "weekly", "monthly", etc.
};
```
