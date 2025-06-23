# Architecture Overview

High-level overview of the nix-mox configuration framework architecture - a comprehensive NixOS configuration system with development tools, monitoring, system management utilities, and messaging support.

## Core Components

### Development & Management

- **Nix-Powered Maintenance & Updates**: Automated system updates and maintenance
- **Development Shells**: Multiple specialized development environments
- **Testing Infrastructure**: Comprehensive unit and integration testing
- **Package Management**: Curated package collections and utilities

### System Management

- **Proxmox Integration**: VM/LXC management and backup utilities
- **ZFS Storage Management**: Snapshot and storage utilities
- **Service Management**: Systemd services and automation
- **Security & Monitoring**: System security and monitoring tools

### Communication & Productivity

- **Messaging & Communication Suite**: Complete messaging platform integration
  - Primary: Signal Desktop, Telegram Desktop, Discord, Slack
  - Video Calling: Zoom, Microsoft Teams, Skype
  - Email: Thunderbird, Evolution
  - Voice & Chat: Mumble, TeamSpeak, IRC clients
- **Productivity Tools**: Communication and collaboration applications

### Gaming & Entertainment

- **Linux Gaming Shell**: Steam, Wine, Lutris, MangoHud, GameMode, DXVK, VKD3D
- **Windows Gaming Support**: League of Legends and other Windows games via Wine/Lutris
- **Helper Scripts**: Wine configuration and game setup automation

### Platform Support

- **Linux Development**: Core development tools and system utilities
- **macOS Development Shell**: macOS-specific frameworks and development tools
- **Cross-Platform Support**: Unified configuration across Linux, macOS, and Windows

## System Architecture

### Network Topology

```mermaid
flowchart TD
    Internet --> Router --> ProxmoxHost
    ProxmoxHost -- vmbr0 --> NixOS_LXC
    ProxmoxHost -- vmbr1 --> Windows_VM
    ProxmoxHost -- vmbr2 --> Admin_PC
    NixOS_LXC --> NixOS_VM
    ProxmoxHost --> Messaging_Services[Signal/Telegram/Discord]
    ProxmoxHost --> Video_Calling[Zoom/Teams/Skype]

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
    rpool --> Messaging_Data["Messaging Data"]
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
    ProxmoxHost -- "Messaging Sync" --> Messaging_Backups["Messaging Data Backup"]

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
| **Audio/Video**| Webcam, Microphone, Audio Interface            |

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
    A --> E[Checks/Tests]
    
    B --> B1[proxmox-update]
    B --> B2[vzdump-backup]
    B --> B3[zfs-snapshot]
    B --> B4[nixos-flake-update]
    B --> B5[install]
    B --> B6[uninstall]
    
    C --> C1[default]
    C --> C2[development]
    C --> C3[testing]
    C --> C4[services]
    C --> C5[monitoring]
    C --> C6[zfs]
    C --> C7[gaming]
    C --> C8[macos]
    C --> C9[storage]
    
    D --> D1[Templates]
    D --> D2[Modules]
    D --> D3[Services]
    D --> D4[Packages]
    
    E --> E1[unit]
    E --> E2[integration]
    E --> E3[test-suite]
```

### Module Integration

```mermaid
graph TD
    A[NixOS Module] --> B[System Services]
    A --> C[Automation Scripts]
    A --> D[Update Services]
    A --> E[Messaging Services]
    
    B --> B1[systemd Services]
    B --> B2[Timers]
    B --> B3[D-Bus Services]
    B --> B4[PipeWire Audio]
    
    C --> C1[Script Installation]
    C --> C2[Path Configuration]
    C --> C3[Helper Scripts]
    
    D --> D1[Daily Updates]
    D --> D2[Flake Updates]
    D --> D3[Backup Automation]
    
    E --> E1[Signal Desktop]
    E --> E2[Telegram Desktop]
    E --> E3[Video Calling]
    E --> E4[Email Clients]
```

### Template System

```mermaid
graph TD
    A[modules/templates/] --> B[base/]
    A --> C[services/]
    A --> D[platforms/]
    A --> E[infrastructure/]
    
    B --> B1[common.nix]
    B --> B2[common/]
    B2 --> B2a[networking.nix]
    B2 --> B2b[display.nix]
    B2 --> B2c[messaging.nix]
    B2 --> B2d[packages.nix]
    B2 --> B2e[services.nix]
    B2 --> B2f[sound.nix]
    B2 --> B2g[graphics.nix]
    B2 --> B2h[programs.nix]
    B2 --> B2i[system.nix]
    B2 --> B2j[nix-settings.nix]
    
    C --> C1[web-server.nix]
    C --> C2[database.nix]
    C --> C3[monitoring.nix]
    C --> C4[load-balancer.nix]
    
    D --> D1[linux.nix]
    D --> D2[macos.nix]
    D --> D3[windows.nix]
    
    E --> E1[ci-runner.nix]
    E --> E2[production.nix]
    E --> E3[development.nix]
```

## Messaging & Communication Architecture

### Messaging Stack

```mermaid
graph TD
    A[Messaging Layer] --> B[Primary Apps]
    A --> C[Video Calling]
    A --> D[Email]
    A --> E[Voice & Chat]
    
    B --> B1[Signal Desktop]
    B --> B2[Telegram Desktop]
    B --> B3[Discord]
    B --> B4[Slack]
    B --> B5[Element Desktop]
    B --> B6[WhatsApp for Linux]
    
    C --> C1[Zoom]
    C --> C2[Microsoft Teams]
    C --> C3[Skype]
    
    D --> D1[Thunderbird]
    D --> D2[Evolution]
    
    E --> E1[Mumble]
    E --> E2[TeamSpeak]
    E --> E3[HexChat]
    E --> E4[WeeChat]
```

### Audio/Video Infrastructure

```mermaid
graph TD
    A[Audio/Video Stack] --> B[PipeWire]
    A --> C[Hardware Support]
    A --> D[Services]
    
    B --> B1[ALSA Support]
    B --> B2[PulseAudio Compat]
    B --> B3[JACK Support]
    B --> B4[WebRTC Support]
    
    C --> C1[Video4Linux2]
    C --> C2[Audio Interfaces]
    C --> C3[Webcams]
    C --> C4[Microphones]
    
    D --> D1[D-Bus Notifications]
    D --> D2[RTKit Real-time]
    D --> D3[GVFS File Access]
```

## Testing Infrastructure

The testing infrastructure is organized under `scripts/tests/` and includes:

- **Unit Tests** (`scripts/tests/unit/`): Individual component testing
- **Integration Tests** (`scripts/tests/integration/`): End-to-end system testing
- **Performance Tests** (`scripts/tests/integration/performance-tests.nu`): System performance validation
- **Test Utilities** (`scripts/tests/lib/`): Common testing functions and helpers
  - `test-utils.nu`: Core test utilities and environment management
  - `test-coverage.nu`: Coverage reporting and aggregation
  - `coverage-core.nu`: Coverage tracking and data collection
  - `shared.nu`: Shared test functions
  - `test-common.nu`: Common test functions

Test execution is managed through multiple methods:

- **Make Commands**: `make test`, `make unit`, `make integration`, `make clean`
- **Nix Flake Checks**: `nix flake check`, granular test execution via flake outputs
- **Direct Nushell**: `nu -c "source scripts/tests/run-tests.nu; run []"`
- **Main Runner**: `scripts/tests/run-tests.nu`: Comprehensive test orchestration

The testing system provides:

- **Coverage Reporting**: Automatic coverage generation in `TEST_TEMP_DIR`
- **Cross-platform Support**: Tests run on Linux, macOS, and Windows
- **Sandbox Compatibility**: Works in Nix build environments
- **CI/CD Integration**: GitHub Actions support via `nix flake check`

For more details, see the [Testing Guide](./../guides/testing.md).

## Package Collections

### Productivity Packages

```mermaid
graph TD
    A[Productivity] --> B[Communication]
    A --> C[Development]
    A --> D[System]
    A --> E[Multimedia]
    
    B --> B1[Signal Desktop]
    B --> B2[Telegram Desktop]
    B --> B3[Discord]
    B --> B4[Slack]
    B --> B5[Element Desktop]
    B --> B6[WhatsApp for Linux]
    B --> B7[Zoom]
    B --> B8[Teams]
    B --> B9[Skype]
    B --> B10[Thunderbird]
    B --> B11[Evolution]
    B --> B12[Mumble]
    B --> B13[TeamSpeak]
    B --> B14[HexChat]
    B --> B15[WeeChat]
    
    C --> C1[Development Tools]
    C --> C2[Error Handling]
    
    D --> D1[System Utilities]
    D --> D2[Linux Packages]
    D --> D3[Windows Packages]
    
    E --> E1[Multimedia Tools]
```

## Security & Monitoring

### Security Components

- **Infisical Integration**: Secrets management and configuration
- **Tailscale VPN**: Secure network connectivity
- **System Hardening**: Security-focused configurations
- **Access Control**: User and permission management

### Monitoring Stack

- **System Monitoring**: Performance and resource tracking
- **Service Monitoring**: Application and service health checks
- **Log Management**: Centralized logging and analysis
- **Alerting**: Notification systems for system events

## Deployment & Configuration

### Configuration Templates

- **Safe Configuration**: Complete desktop setup with display safety and messaging support
- **CI Runner**: High-performance CI/CD environment
- **Web Server**: Production web server configuration
- **Database**: Database server setup
- **Monitoring**: Prometheus/Grafana monitoring stack
- **Load Balancer**: HAProxy configuration

### Fragment System

The fragment system allows modular configuration composition:

- **Base Fragments**: Core system components (networking, display, messaging, packages)
- **Service Fragments**: Individual service configurations
- **Platform Fragments**: Platform-specific configurations
- **Infrastructure Fragments**: Infrastructure and deployment configurations

### Cross-Platform Support

- **Linux**: Full NixOS integration with all features
- **macOS**: Development tools and macOS-specific frameworks
- **Windows**: Limited support through WSL and development tools
- **Proxmox**: Complete virtualization and container management

For detailed usage instructions, see the [Usage Guide](./../USAGE.md) and [Examples](./../nixamples/).
