# Hardware Drivers Guide

This guide provides information on configuring and troubleshooting hardware drivers for NixOS systems, with a focus on gaming and virtualization scenarios (e.g., Proxmox).

---

## Table of Contents

- [NVIDIA](#nvidia)
- [AMD](#amd)
- [Intel](#intel)
- [General Troubleshooting](#general-troubleshooting)

---

## NVIDIA

### Enabling the NVIDIA Driver in NixOS

Add the following to your NixOS configuration:

```nix
services.xserver.videoDrivers = [ "nvidia" ];
hardware.opengl.enable = true;
hardware.opengl.driSupport = true;
hardware.opengl.driSupport32Bit = true;
hardware.pulseaudio.support32Bit = true;
```

> **Note:** These settings are enabled by default in the nix-mox NixOS VM template for maximum compatibility.

### Troubleshooting

- If you see a black screen or blinking cursor, check for `nouveau` errors in `journalctl -b -p err`.
- Ensure you are not using both `nvidia` and `nouveau` drivers at the same time.
- For GPU passthrough (Proxmox), ensure IOMMU and VFIO are configured correctly.
- Use `nvidia-smi` to check driver status.

### Special Notes

- For gaming, ensure Vulkan support is enabled (`vulkan-tools`, `vulkan-loader`).
- For virtualization, see the [nixos-on-proxmox.md](./nixos-on-proxmox.md) guide.

---

## AMD

### Enabling the AMD Driver in NixOS

AMD GPUs are supported out of the box with the `amdgpu` or `radeon` drivers:

```nix
services.xserver.videoDrivers = [ "amdgpu" ];
# or for older cards:
# services.xserver.videoDrivers = [ "radeon" ];
```

### Troubleshooting

- Check for firmware errors in `journalctl`.
- Ensure your kernel is recent for best support.

### Special Notes

- Vulkan is supported on most modern AMD GPUs.

---

## Intel

### Enabling the Intel Driver in NixOS

Intel GPUs are supported with the `modesetting` or `intel` drivers:

```nix
services.xserver.videoDrivers = [ "modesetting" ];
# or
# services.xserver.videoDrivers = [ "intel" ];
```

### Troubleshooting

- For newer hardware, prefer `modesetting`.
- Check for missing firmware in `journalctl`.

---

## General Troubleshooting

- Use `journalctl -b -p err` to check for driver errors after boot.
- For gaming, verify Vulkan and OpenGL support with `vulkaninfo` and `glxinfo`.
- For passthrough, verify IOMMU and VFIO configuration.
- Consult the [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) guide for more help.

---

For further assistance, open an issue or consult the NixOS manual and community forums.
