# NixOS on Proxmox Guide

Terse guide for deploying NixOS on Proxmox via LXC, VM, or distroless containers.

## Deployment Options

```mermaid
graph TD
    A[NixOS on Proxmox] --> B[LXC Container]
    A --> C[VM]
    A --> D[Distroless]
    
    B --> B1[Lightweight]
    B --> B2[Fast Boot]
    B --> B3[Resource Efficient]
    
    C --> C1[Full VM]
    C --> C2[Declarative]
    C --> C3[Remote Updates]
    
    D --> D1[Minimal]
    D --> D2[Secure]
    D --> D3[OCI Compatible]
```

## LXC Container Setup

```mermaid
flowchart TD
    A[Download Image] --> B[Upload to Proxmox]
    B --> C[Create Container]
    C --> D[Configure]
    D --> E[Start Services]
    
    A --> A1[Hydra]
    B --> B1[Local Storage]
    C --> C1[pct create]
    D --> D1[SSH Keys]
```

### Quick Setup

```bash
# Create container
pct create <VMID> local:vztmpl/nixos-*.tar.xz \
  --ostype unmanaged \
  --features nesting=1 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp
```

## VM Deployment

```mermaid
flowchart TD
    A[Prepare Config] --> B[Build Image]
    B --> C[Upload to Proxmox]
    C --> D[Create VM]
    D --> E[Restore Image]
    
    A --> A1[QEMU Guest Agent]
    B --> B1[nixos-generate]
    C --> C1[vzdump]
    D --> D1[Detach Disk]
    E --> E1[qmrestore]
```

### Configuration

```nix
# configuration.nix
{ config, ... }: {
  imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];
  services.qemuGuest.enable = true;
}
```

### Build & Deploy

```bash
# Build image
nixos-generate -f proxmox -c configuration.nix

# Deploy
qmrestore /path/to/image.vma.zst <VMID>

# Remote update
nixos-rebuild switch --flake .#myVmName --target-host root@vm-ip
```

## Distroless Containers

```mermaid
graph TD
    A[Build Image] --> B[Runtime Dependencies]
    A --> C[Build Dependencies]
    
    B --> D[Final Image]
    C --> E[Build Environment]
    
    D --> F[Deploy]
    E --> G[Build Process]
```

### Minimal Example

```nix
# Minimal nginx container
pkgs.dockerTools.buildImage {
  name = "distroless-app";
  config = { 
    Cmd = [ "${pkgs.nginx}/bin/nginx" "-g" "daemon off;" ]; 
  };
}
```

### Multi-stage Build

```nix
# Multi-stage container build
let
  buildEnv = pkgs.buildEnv { ... };
  runtimeEnv = pkgs.runtimeOnlyDependencies buildEnv;
in
pkgs.dockerTools.buildImage {
  copyToRoot = runtimeEnv;
}
```

### Flake Configuration

```nix
# flake.nix
{
  outputs = { nixpkgs, ... }: {
    nixosConfigurations.my-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ({ pkgs, ... }: {
        environment.systemPackages = [ pkgs.nginx ];
        system.stateVersion = "24.11";
        boot.isContainer = true;
      }) ];
    };
  };
}
```

## Update Flow

```mermaid
flowchart TD
    A[Local Changes] --> B[Build]
    B --> C{Deployment Type}
    
    C -->|LXC| D[Container Update]
    C -->|VM| E[VM Update]
    C -->|Distroless| F[Image Update]
    
    D --> G[Apply Changes]
    E --> G
    F --> G
```

## Resource Allocation

```mermaid
graph TD
    A[Resource Planning] --> B[CPU]
    A --> C[Memory]
    A --> D[Storage]
    
    B --> B1[LXC: Shared]
    B --> B2[VM: Dedicated]
    
    C --> C1[LXC: Flexible]
    C --> C2[VM: Fixed]
    
    D --> D1[LXC: Thin]
    D --> D2[VM: Thick]
```
