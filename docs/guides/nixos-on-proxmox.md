# NixOS on Proxmox Guide

## Deployment Options

```mermaid
graph TD
    A[NixOS on Proxmox] --> B[LXC: Lightweight/Fast]
    A --> C[VM: Full/Declarative]
    A --> D[Distroless: Minimal/Secure]
```

## LXC Container Setup

```mermaid
flowchart TD
    A[Download Image] --> B[Upload to Proxmox]
    B --> C[Create Container]
    C --> D[Configure & Start]
```

### Quick Setup

```bash
pct create <VMID> local:vztmpl/nixos-*.tar.xz \
  --ostype unmanaged \
  --features nesting=1 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp
```

## VM Deployment

```mermaid
flowchart TD
    A[Config] --> B[Build Image]
    B --> C[Upload & Deploy]
```

### Configuration

```nix
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
    A[Build] --> B[Runtime]
    A --> C[Build Env]
    B --> D[Deploy]
```

### Minimal Example

```nix
pkgs.dockerTools.buildImage {
  name = "distroless-app";
  config = { 
    Cmd = [ "${pkgs.nginx}/bin/nginx" "-g" "daemon off;" ]; 
  };
}
```

### Flake Configuration

```nix
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
    A[Changes] --> B[Build]
    B --> C{Type}
    C -->|LXC/VM/Distroless| D[Deploy]
```

## Resource Allocation

```mermaid
graph TD
    A[Resources] --> B[CPU: Shared/Dedicated]
    A --> C[Memory: Flexible/Fixed]
    A --> D[Storage: Thin/Thick]
```
