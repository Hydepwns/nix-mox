# Advanced Configuration Guide

## Network Architecture

```mermaid
graph TD
    A[Proxmox Host] --> B[vmbr0: NixOS/Trusted]
    A --> C[vmbr1: Windows/Untrusted]
    A --> D[vmbr2: Management]
```

## Storage Configuration

```mermaid
flowchart TD
    A[Proxmox Host] --> B[virtio-fs]
    B --> C[NixOS Guest]
    A --> D[/mnt/host/windows-share]
    C --> E[/mnt/guest/win-mount]
```

### Shared Storage

```nix
virtualisation.sharedDirectories = {
  win-share = {
    source = "/mnt/host/windows-share";
    target = "/mnt/guest/win-mount";
  };
};
```

## Security Architecture

```mermaid
graph TD
    A[Security] --> B[Read-only Root]
    A --> C[Non-root Services]
    A --> D[SBOM]
```

### Security Config

```nix
# Read-only root
fileSystems."/".options = [ "ro" "nosuid" "nodev" ];

# Non-root service
users.users.nginx = {
  isSystemUser = true;
  group = "nginx";
};
services.nginx.user = "nginx";

# Generate SBOM
nix store make-content-addressable /nix/store/...-nginx-* --rewrite-outputs > sbom.json
```

## Monitoring & Updates

```mermaid
flowchart TD
    A[System State] --> B[Logging]
    A --> C[Updates]
    B --> D[Central Logs]
    C --> E[System State]
```

### Monitoring Setup

```nix
# Unified logging
services.journald.extraConfig = ''
  ForwardToSyslog=yes
  MaxLevelSyslog=debug
'';

# Automatic updates
system.autoUpgrade = {
  enable = true;
  flake = "github:user/nix-config#my-container";
  dates = "daily";
};
```

## System State Flow

```mermaid
graph TD
    A[Config] --> B[Build]
    B --> C{Update Type}
    C -->|Auto/Manual| D[Apply]
    D --> E[New State]
    E --> F[Verify]
    F --> G[Rollback if needed]
```

## Resource Isolation

```mermaid
graph TD
    A[Resources] --> B[CPU: Quotas/Priorities]
    A --> C[Memory: Limits/Reservations]
    A --> D[Storage: Quotas/Snapshots]
    A --> E[Network: Bandwidth/Firewall]
```

## Gaming Advanced Configuration

```mermaid
graph TD
    A[Gaming VM] --> B[GPU Passthrough]
    B --> C[Performance Tuning]
    C --> D[Game Installation]
    D --> E[Automated Updates]
```

### Performance Tuning

```nix
{ config, ... }: {
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;
}
```
