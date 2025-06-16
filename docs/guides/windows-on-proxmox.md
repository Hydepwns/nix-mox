# Windows on Proxmox Guide

## VM Creation Flow

```mermaid
flowchart TD
    A[Create VM] --> B[System Settings]
    B --> C[Storage Setup]
    C --> D[Network Config]
    D --> E[PCI Passthrough]
    E --> F[Install Windows]
    F --> G[Install Drivers]
```

## System Configuration

```mermaid
graph TD
    A[VM Settings] --> B[System: OVMF/Q35/Host CPU]
    A --> C[Storage: VirtIO Block/SCSI]
    A --> D[Network: VirtIO Net]
    A --> E[PCI: GPU/USB Controller]
```

## Quick Setup

1. **Create VM**

   ```bash
   # System
   - BIOS: OVMF (UEFI)
   - Machine: q35
   - CPU: host
   
   # Storage
   - Bus: VirtIO Block/SCSI
   
   # Network
   - Model: VirtIO
   ```

2. **Install Drivers**

   ```bash
   # Download & attach VirtIO ISO
   wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
   
   # Required drivers
   - viostor (storage)
   - NetKVM (network)
   - QEMU Guest Agent
   ```

3. **PCI Passthrough**

   ```bash
   # Add to VM config
   -device vfio-pci,host=01:00.0,multifunction=on  # GPU
   -device vfio-pci,host=01:00.1                  # GPU Audio
   -device vfio-pci,host=03:00.0                  # USB Controller
   ```

## Update Flow

```mermaid
flowchart TD
    A[Windows VM] --> B[QEMU Guest Agent]
    B --> C[Proxmox Host]
    C --> D[Backup System]
    D --> E[ZFS Snapshots]
```

## Maintenance

```mermaid
graph TD
    A[Tasks] --> B[Updates: Windows/Drivers/Agent]
    A --> C[Backups: VZDump/ZFS]
    A --> D[Snapshots: Before Updates/Changes]
```

## Troubleshooting

```mermaid
flowchart TD
    A[Issue] --> B{Type}
    B -->|Performance| C[Check CPU/RAM]
    B -->|Graphics| D[Verify Passthrough]
    B -->|Network/Storage| E[VirtIO Drivers]
    C --> F[Solution]
    D --> F
    E --> F
```

For detailed troubleshooting and advanced configuration, see the [Proxmox PCI Passthrough Guide](https://pve.proxmox.com/wiki/Pci_passthrough).
