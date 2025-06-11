# Windows on Proxmox Guide

Terse guide for setting up Windows VMs on Proxmox with GPU passthrough.

## VM Creation Flow

```mermaid
flowchart TD
    A[Create VM] --> B[System Settings]
    B --> C[Storage Setup]
    C --> D[Network Config]
    D --> E[PCI Passthrough]
    E --> F[Install Windows]
    F --> G[Install Drivers]
    G --> H[Configure Updates]
```

## System Configuration

```mermaid
graph TD
    A[VM Settings] --> B[System]
    A --> C[Storage]
    A --> D[Network]
    A --> E[PCI Devices]
    
    B --> B1[OVMF/UEFI]
    B --> B2[Q35 Machine]
    B --> B3[Host CPU]
    
    C --> C1[VirtIO Block]
    C --> C2[VirtIO SCSI]
    
    D --> D1[VirtIO Net]
    
    E --> E1[GPU]
    E --> E2[USB Controller]
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
    
    A --> F[Windows Update]
    F --> G[Driver Updates]
    G --> H[System Maintenance]
```

## Maintenance

```mermaid
graph TD
    A[Regular Tasks] --> B[Updates]
    A --> C[Backups]
    A --> D[Snapshots]
    
    B --> B1[Windows]
    B --> B2[Drivers]
    B --> B3[QEMU Agent]
    
    C --> C1[VZDump]
    C --> C2[ZFS]
    
    D --> D1[Before Updates]
    D --> D2[Before Changes]
```

## Troubleshooting

```mermaid
flowchart TD
    A[Issue] --> B{Type}
    B -->|Performance| C[Check CPU/RAM]
    B -->|Graphics| D[Verify Passthrough]
    B -->|Network| E[VirtIO Drivers]
    B -->|Storage| F[VirtIO Drivers]
    
    C --> G[Solution]
    D --> G
    E --> G
    F --> G
```

For detailed troubleshooting and advanced configuration, see the [Proxmox PCI Passthrough Guide](https://pve.proxmox.com/wiki/Pci_passthrough).
