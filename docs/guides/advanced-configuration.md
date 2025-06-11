# Advanced Configuration Guide

Terse guide for advanced networking, storage, security, and monitoring in NixOS + Proxmox.

## Network Architecture

```mermaid
graph TD
    A[Proxmox Host] --> B[vmbr0]
    A --> C[vmbr1]
    A --> D[vmbr2]
    
    B --> B1[NixOS VMs]
    B --> B2[Trusted Containers]
    
    C --> C1[Windows VMs]
    C --> C2[Untrusted Systems]
    
    D --> D1[Management]
    D --> D2[OOB Access]
    
    B1 --> E[Internet]
    C1 --> E
    D1 --> E
```

## Storage Configuration

```mermaid
flowchart TD
    A[Proxmox Host] --> B[virtio-fs]
    B --> C[NixOS Guest]
    
    A --> D[/mnt/host/windows-share]
    C --> E[/mnt/guest/win-mount]
    
    D --> F[Shared Files]
    E --> F
```

### Shared Storage Setup

```nix
# configuration.nix
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
    A[Security Measures] --> B[Read-only Root]
    A --> C[Non-root Services]
    A --> D[SBOM]
    
    B --> B1[Immutable System]
    B --> B2[Secure Boot]
    
    C --> C1[Service Isolation]
    C --> C2[Privilege Limits]
    
    D --> D1[Dependency Audit]
    D --> D2[Supply Chain]
```

### Security Configurations

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
    
    B --> B1[Journald]
    B --> B2[Syslog]
    
    C --> C1[Auto Upgrade]
    C --> C2[Manual Update]
    
    B1 --> D[Central Logs]
    B2 --> D
    C1 --> E[System State]
    C2 --> E
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
    A[Configuration] --> B[Build]
    B --> C{Update Type}
    
    C -->|Auto| D[Schedule]
    C -->|Manual| E[Trigger]
    
    D --> F[Apply]
    E --> F
    
    F --> G[New State]
    G --> H[Verify]
    H --> I[Rollback if needed]
```

## Resource Isolation

```mermaid
graph TD
    A[System Resources] --> B[CPU]
    A --> C[Memory]
    A --> D[Storage]
    A --> E[Network]
    
    B --> B1[Quotas]
    B --> B2[Priorities]
    
    C --> C1[Limits]
    C --> C2[Reservations]
    
    D --> D1[Quotas]
    D --> D2[Snapshots]
    
    E --> E1[Bandwidth]
    E --> E2[Firewall]
```
