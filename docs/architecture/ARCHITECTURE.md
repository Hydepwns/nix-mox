# Architecture Overview

High-level overview of the Proxmox + NixOS + Windows setup architecture.

## Core Components

- Nix-Powered Maintenance & Updates
- Windows VM with Steam/Rust
- LXC/VM Templates
- Development Tools
- **Linux & Windows Gaming Shell**
  - Gaming shell with Steam, Wine, Lutris, MangoHud, GameMode, DXVK, VKD3D
  - Helper scripts for Wine and League of Legends setup
  - League of Legends and other Windows games via Wine/Lutris
- **macOS Development Shell**
  - Core development tools (git, nix, nixpkgs-fmt)
  - macOS-specific frameworks (CoreServices, Foundation)
  - Development tools (vscode, jq, yq, curl)
  - Terminal tools (tmux, zsh, oh-my-zsh)
  - System monitoring tools (htop)

## System Architecture

### Network Topology

```mermaid
flowchart TD
    Internet --> Router --> ProxmoxHost
    ProxmoxHost -- vmbr0 --> NixOS_LXC
    ProxmoxHost -- vmbr1 --> Windows_VM
    ProxmoxHost -- vmbr2 --> Admin_PC
    NixOS_LXC --> NixOS_VM

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
    rpool --> Backups["Backups"]
    rpool --> Shared_Storage["Shared Storage"]
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
    ProxmoxHost -- "vzdump backups" --> Proxmox_Backups
    Proxmox_Backups -- "store" --> Storage["rpool or external"]

    ProxmoxHost["Proxmox Host"]
    NixOS_LXC_VM["NixOS LXC/VM"]
    Windows_VM["Windows VM"]
    Proxmox_Backups["Proxmox Backups"]
```

## Hardware & Configuration

### Hardware Example

| Component      | Model/Details                                  |
|----------------|------------------------------------------------|
| **CPU**        | AMD Ryzen 5950X (16c/32t)                      |
| **RAM**        | 128GB ECC DDR4                                 |
| **Storage**    | 2x2TB NVMe (ZFS mirror), 4x8TB HDD (ZFS RAIDZ1) |
| **GPU**        | NVIDIA RTX 3060 (Windows passthrough)          |
| **Network**    | 2x 2.5GbE (Intel i225-V)                       |

### PCI Passthrough

- GPU: 01:00.0, 01:00.1 (audio)
- USB controller: 03:00.0

## Nix Integration

### Flake Structure

```mermaid
graph TD
    A[Flake.nix] --> B[Packages]
    A --> C[DevShells]
    A --> D[NixOS Modules]
    
    B --> B1[proxmox-update]
    B --> B2[vzdump-backup]
    B --> B3[zfs-snapshot]
    
    C --> C1[default]
    C --> C2[development]
    C --> C3[testing]
    C --> C4[services]
    C --> C5[monitoring]
    C --> C6[zfs]
    C --> C7[gaming]
    C --> C8[macos]
    C7 --> C7a[League of Legends Helper]
    C7 --> C7b[Wine Config Helper]
    C8 --> C8a[macOS Frameworks]
    C8 --> C8b[Development Tools]
```

### Module Integration

```mermaid
graph TD
    A[NixOS Module] --> B[System Services]
    A --> C[Automation Scripts]
    A --> D[Update Services]
    
    B --> B1[systemd Services]
    B --> B2[Timers]
    
    C --> C1[Script Installation]
    C --> C2[Path Configuration]
    
    D --> D1[Daily Updates]
    D --> D2[Flake Updates]
```

## Testing Infrastructure

The testing infrastructure is organized under `tests/` and includes:

- **Unit Tests** (`tests/unit/`): Individual component testing
- **Integration Tests** (`tests/integration/`): End-to-end system testing
- **Performance Tests** (`tests/integration/performance-tests.nu`): System performance validation
- **Test Utilities** (`tests/lib/`): Common testing functions and helpers
  - `test-utils.nu`: Core test utilities and environment management
  - `test-coverage.nu`: Coverage reporting and aggregation
  - `coverage-core.nu`: Coverage tracking and data collection
  - `shared.nu`: Shared test functions
  - `test-common.nu`: Common test functions

Test execution is managed through multiple methods:

- **Make Commands**: `make test`, `make unit`, `make integration`, `make clean`
- **Nix Flake Checks**: `nix flake check`, granular test execution via flake outputs
- **Direct Nushell**: `nu -c "source tests/run-tests.nu; run []"`
- **Main Runner**: `tests/run-tests.nu`: Comprehensive test orchestration

The testing system provides:

- **Coverage Reporting**: Automatic coverage generation in `TEST_TEMP_DIR`
- **Cross-platform Support**: Tests run on Linux, macOS, and Windows
- **Sandbox Compatibility**: Works in Nix build environments
- **CI/CD Integration**: GitHub Actions support via `nix flake check`

For more details, see the [Testing Guide](./../guides/testing.md).
