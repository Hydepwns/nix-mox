# Windows on Proxmox Guide

This guide provides best practices for creating and configuring a Windows virtual machine on Proxmox, including PCI passthrough for devices like GPUs.

---

### 1. Create the VM

When creating a Windows VM in the Proxmox UI, use the following settings for best performance and compatibility:

- **OS**: Select the appropriate Windows version.
- **System**:
  - **Guest Agent**: Enable `QEMU Guest Agent`.
  - **BIOS**: `OVMF (UEFI)`.
  - **Machine**: `q35`.
- **Disks**:
  - **Bus/Device**: `SCSI` or `VirtIO Block`. Using `SCSI` with the `VirtIO SCSI` controller type is often recommended.
- **CPU**:
  - **Type**: `host`.
- **Network**:
  - **Model**: `VirtIO (paravirtualized)`.

### 2. Attach VirtIO Drivers

Windows does not have VirtIO drivers built-in. You must provide them during installation.

1. Download the latest stable VirtIO drivers ISO from [the official Fedora repository](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso).
2. Upload the ISO to your Proxmox storage.
3. Attach the VirtIO drivers ISO to the VM as a secondary CD/DVD drive alongside your Windows installation ISO.
4. During Windows setup, when prompted to choose an installation disk, it may appear empty. Click "Load driver" and browse to the VirtIO ISO to install the appropriate drivers for your storage controller (`viostor` for VirtIO Block/SCSI) and network card (`NetKVM`).

### 3. PCI Passthrough (GPU, etc.)

To pass a physical device like a GPU to a Windows VM:

1. Follow the Proxmox documentation for [PCI(e) Passthrough](https://pve.proxmox.com/wiki/Pci_passthrough). This involves enabling IOMMU, isolating the device from the host, and other host-level configurations.
2. Once the host is configured, add the device to your VM via the "Hardware" tab in the Proxmox UI or by editing the VM's configuration file (`/etc/pve/qemu-server/<VMID>.conf`).

    ```
    # Example for passing through a GPU
    -device vfio-pci,host=01:00.0,multifunction=on
    ```

### 4. Install QEMU Guest Agent

After Windows is installed, install the QEMU Guest Agent from the attached VirtIO drivers ISO. This will improve integration with the Proxmox host, allowing for proper shutdowns, reboots, and information reporting in the Proxmox UI.
