# Architecture Overview

This document provides a high-level overview of the architecture, network topology, storage layout, update and backup flow, and hardware for the Proxmox + NixOS + Windows setup. For usage and configuration details, see the [USAGE.md](./USAGE.md).

## Table of Contents

- [Core Components](#core-components)
- [System Architecture](#system-architecture)
  - [Network Topology](#network-topology)
  - [Storage Layout](#storage-layout)
  - [Update & Backup Flow](#update--backup-flow)
- [Hardware & Configuration](#hardware--configuration)
  - [Hardware Example](#hardware-example)
  - [PCI Passthrough](#pci-passthrough)
- [Nix Integration](#nix-integration)
  - [Flake Structure](#flake-structure)
  - [Automation Flow](#automation-flow)
  - [Module Integration](#module-integration)
- [Testing Infrastructure](#testing-infrastructure)

## Core Components

```mermaid
graph LR
    A[Core Features] --> B[Nix-Powered]
    A --> C[Windows VM]
    A --> D[Templates]
    A --> E[Dev Tools]
    B --> F[Maintenance]
    B --> G[Updates]
    C --> H[Steam/Rust]
    D --> I[LXC/VM]
    E --> J[nix develop]
```

## System Architecture

### Network Topology

> **Note:** Diagrams use [Mermaid](https://mermaid-js.github.io/) syntax. Rendered diagrams require a compatible Markdown viewer (e.g., GitHub, VS Code, Obsidian).

```mermaid
flowchart TD
    Internet --> Router --> ProxmoxHost
    ProxmoxHost -- vmbr0 --> NixOS_LXC
    ProxmoxHost -- vmbr1 --> Windows_VM
    ProxmoxHost -- vmbr2 --> Admin_PC
    NixOS_LXC --> NixOS_VM

    %% Display names
    ProxmoxHost["Proxmox Host"]
    NixOS_LXC["NixOS LXC"]
    Windows_VM["Windows VM"]
    Admin_PC["Admin PC"]
    NixOS_VM["NixOS VM"]
```

### Storage Layout

```mermaid
graph TD
    rpool["ZFS Pool: rpool"]
    rpool --> VM_Disks
    VM_Disks["VM Disks"]
    VM_Disks --> NixOS_VM["NixOS VM"]
    VM_Disks --> Windows_VM["Windows VM"]
    rpool --> LXC_Containers["LXC Containers"]
    rpool --> Backups["Backups (Proxmox)"]
    rpool --> Shared_Storage["Shared Storage (/mnt/windows, virtio-fs)"]
```

### Update & Backup Flow

```mermaid
flowchart TD
    Internet --> ProxmoxHost
    ProxmoxHost -- "nix flake update" --> NixOS_LXC_VM
    NixOS_LXC_VM -- "nixos-rebuild switch" --> NixOS_LXC_VM
    NixOS_LXC_VM -- "ZFS snapshot" --> NixOS_LXC_VM
    ProxmoxHost -- "Windows Update" --> Windows_VM
    Windows_VM -- "QEMU guest agent" --> Windows_VM
    Windows_VM -- "ZFS snapshot" --> Windows_VM
    ProxmoxHost -- "vzdump backups" --> Proxmox_Backups
    Proxmox_Backups -- "store" --> Storage["rpool or external (NAS, USB)"]
    Proxmox_Backups -- "restore" --> ProxmoxHost
    NixOS_LXC_VM -- "rollback" --> NixOS_LXC_VM
    Windows_VM -- "rollback" --> Windows_VM

    %% Display names
    ProxmoxHost["Proxmox Host"]
    NixOS_LXC_VM["NixOS LXC/VM"]
    Windows_VM["Windows VM"]
    Proxmox_Backups["Proxmox Backups"]
```

## Hardware & Configuration

### Hardware Example

> **Note:** The following hardware is a personal example. Adapt these specs to your own needs and available hardware.

| Component      | Model/Details                                  |
|----------------|------------------------------------------------|
| **CPU**        | AMD Ryzen 5950X (16c/32t, virtualization OK)   |
| **RAM**        | 128GB ECC DDR4                                 |
| **Storage**    | 2x2TB NVMe (ZFS mirror), 4x8TB HDD (ZFS RAIDZ1) |
| **GPU**        | NVIDIA RTX 3060 (Windows passthrough)          |
| **Network**    | 2x 2.5GbE (Intel i225-V)                       |
| **Proxmox**    | 8.1                                            |

The host is configured with:

- NixOS LXC (for services, immutable)
- NixOS VM (for atomic updates)
- Windows VM (for GPU passthrough, apps)

### PCI Passthrough

Example PCI devices passed through to VMs:

- GPU: 01:00.0, 01:00.1 (audio)
- USB controller: 03:00.0

For more details, see the [Windows on Proxmox Guide](./docs/guides/windows-on-proxmox.md).

## Nix Integration

### Flake Structure

```mermaid
graph TD
    A[Flake.nix] --> B[Packages]
    A --> C[Apps]
    A --> D[DevShell]
    A --> E[NixOS Modules]
    
    B --> B1[proxmox-update]
    B --> B2[vzdump-backup]
    B --> B3[zfs-snapshot]
    B --> B4[nixos-flake-update]
    
    C --> C1[nix run .#proxmox-update]
    C --> C2[nix run .#vzdump-backup]
    C --> C3[nix run .#zfs-snapshot]
    C --> C4[nix run .#nixos-flake-update]
    
    D --> D1[Nushell]
    D --> D2[Git]
    D --> D3[Nix]
    D --> D4[Development Tools]
    
    E --> E1[System Services]
    E --> E2[Automation Scripts]
    E --> E3[Update Services]
```

### Automation Flow

```mermaid
flowchart TD
    A[User] --> B[nix run]
    B --> C{Script Type}
    
    C -->|proxmox-update| D[Proxmox Host]
    C -->|vzdump-backup| E[Backup System]
    C -->|zfs-snapshot| F[ZFS Storage]
    C -->|nixos-flake-update| G[NixOS Systems]
    
    D --> D1[Update Packages]
    D --> D2[System Maintenance]
    
    E --> E1[VM Backups]
    E --> E2[Container Backups]
    E --> E3[Storage Management]
    
    F --> F1[Create Snapshots]
    F --> F2[Prune Old Snapshots]
    F --> F3[Storage Optimization]
    
    G --> G1[Update Flakes]
    G --> G2[Rebuild Systems]
    G --> G3[Service Updates]
```

### Module Integration

```mermaid
graph TD
    A[NixOS Module] --> B[System Services]
    A --> C[Automation Scripts]
    A --> D[Update Services]
    
    B --> B1[systemd Services]
    B --> B2[Timers]
    B --> B3[User Services]
    
    C --> C1[Script Installation]
    C --> C2[Path Configuration]
    C --> C3[Permissions]
    
    D --> D1[Daily Updates]
    D --> D2[Flake Updates]
    D --> D3[System Rebuilds]
    
    B1 --> E[System Integration]
    C1 --> E
    D1 --> E
```

## Testing Infrastructure

```mermaid
graph TD
    A[GitHub Actions] --> B[Build & Test]
    B --> C[Nushell Tests]
    B --> D[NixOS Module Tests]
    B --> E[Package Builds]
    B --> F[Format & Lint]
    C --> G[Test Results]
    D --> G
    E --> G
    F --> G
```

### Test Components

1. **Nushell Tests** (`tests/`)
   - Unit tests (`unit-tests.nu`)
   - Integration tests (`integration-tests.nu`)
   - Performance tests (`performance-tests.nu`)
   - Test utilities (`test-utils.nu`)

2. **NixOS Module Tests**
   - Module integration
   - Configuration validation
   - Service verification
   - Dependency checks

3. **Build Verification**
   - Multi-architecture builds
   - Package verification
   - Flake compatibility

4. **Code Quality**
   - Nushell formatting/linting
   - Nix code formatting
   - Documentation validation

For more details on testing, see the [Testing Guide](./docs/testing.md).
