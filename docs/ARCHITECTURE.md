# Architecture Overview

This document provides a high-level overview of the architecture, network topology, storage layout, update and backup flow, and hardware for the Proxmox + NixOS + Windows setup. For usage and configuration details, see the [USAGE.md](./USAGE.md).

---

## Table of Contents

- [Network Topology](#network-topology)
- [Storage Layout](#storage-layout)
- [Update & Backup Flow](#update--backup-flow)
- [Hardware Example](#hardware-example)
- [PCI Passthrough](#pci-passthrough)
- [Making nix-mox Scripts NixOS-Native](#making-nix-mox-scripts-nixos-native)
- [Testing & CI/CD](#testing--cicd)

---

## Network Topology

> **Note:** Diagrams use [Mermaid](https://mermaid-js.github.io/) syntax. Rendered diagrams require a compatible Markdown viewer (e.g., GitHub, VS Code, Obsidian).

This section illustrates the logical network connections between Proxmox, NixOS, Windows, and admin systems.

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

## Storage Layout

This section shows how storage is organized, including ZFS pools, VM disks, containers, backups, and shared storage.

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

## Update & Backup Flow

This section outlines the flow of updates and backups for both NixOS and Windows systems, as well as how snapshots and restores are managed.

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

## Hardware Example

> **Note:** The following hardware is a personal example. Adapt these specs to your own needs and available hardware.

| Component      | Model/Details                                  |
|----------------|------------------------------------------------|
| **CPU**        | AMD Ryzen 5950X (16c/32t, virtualization OK)   |
| **RAM**        | 128GB ECC DDR4                                 |
| **Storage**    | 2x2TB NVMe (ZFS mirror), 4x8TB HDD (ZFS RAIDZ1) |
| **GPU**        | NVIDIA RTX 3060 (Windows passthrough)          |
| **Network**    | 2x 2.5GbE (Intel i225-V)                       |
| **Proxmox**    | 8.1                                            |

The host is configured with the following:

- NixOS LXC (for services, immutable)
- NixOS VM (for atomic updates)
- Windows VM (for GPU passthrough, apps)

For more on adapting the architecture to your hardware, see the guides in [USAGE.md](./USAGE.md).

## PCI Passthrough

This section lists example PCI devices passed through to VMs. Update these values for your own hardware as needed.

- GPU: 01:00.0, 01:00.1 (audio)
- USB controller: 03:00.0

For more details, see the [Windows on Proxmox Guide](./docs/windows-on-proxmox.md).

## Making nix-mox Scripts NixOS-Native

For packaging and exposing scripts as Nix derivations and flake apps, see the detailed instructions in [USAGE.md](./USAGE.md#using-the-nixos-module-optional) and your `flake.nix`.

## Testing & CI/CD

This project uses GitHub Actions for continuous integration and deployment. The CI/CD pipeline ensures code quality and reliability through automated testing and building.

### Test Infrastructure

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

1. **Nushell Tests**
   - Located in `tests/` directory
   - Comprehensive test suite using Nushell's native testing capabilities
   - Tests include:
     - Argument parsing and validation
     - Platform detection and validation
     - Script handling and execution
     - Logging functionality
     - Error handling and reporting
   - Uses Nushell's built-in `assert` for validation
   - Supports both unit and integration testing

2. **NixOS Module Tests**
   - Tests module integration
   - Verifies configuration options
   - Ensures systemd service setup
   - Validates module dependencies

3. **Build Verification**
   - Multi-architecture builds (x86_64-linux, aarch64-linux)
   - Package build verification
   - Flake compatibility checks

4. **Code Quality**
   - Nushell code formatting and linting
   - Nix code formatting (nixpkgs-fmt)
   - Documentation validation

### CI/CD Pipeline

The pipeline runs on:

- Every push to `main`
- Every pull request
- Every version tag (v*)

For detailed CI/CD configuration, see `.github/workflows/ci.yml`.

### Running Tests Locally

To run the test suite locally:

1. Ensure Nushell is installed (version 0.80.0 or higher)
2. Run the test suite:

```bash
nu scripts/run-tests.nu
```

The test suite will:
- Execute all test modules
- Validate script functionality
- Check error handling
- Verify logging capabilities
- Report test results

For more detailed test output, use the `--verbose` flag:

```bash
nu scripts/run-tests.nu --verbose
```

### Test Modules

1. **Unit Tests** (`tests/unit-tests.nu`)
   - Tests individual functions and components
   - Validates argument parsing
   - Checks error handling
   - Verifies logging functionality

2. **Integration Tests** (`tests/integration-tests.nu`)
   - Tests script interactions
   - Validates platform detection
   - Checks script execution
   - Verifies system integration

3. **Performance Tests** (`tests/performance-tests.nu`)
   - Measures script execution time
   - Validates resource usage
   - Checks memory consumption
   - Verifies CPU utilization

### Test Utilities

The `tests/test-utils.nu` module provides common testing utilities:

- Test environment setup
- Mock functions
- Assertion helpers
- Logging utilities
- Error handling helpers

For more details on testing, see the [Testing Guide](./docs/testing.md).
