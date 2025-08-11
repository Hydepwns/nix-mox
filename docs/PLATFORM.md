# Platform-Specific Setup

> Quick setup guides for different platforms and environments.

## Proxmox VE

### Quick Setup

```bash
# Use the unified setup
nu scripts/setup/unified-setup.nu

# Or manually configure
services.nix-mox.templates.customOptions.safe-configuration = {
  hostname = "my-nixos-system";
  username = "myuser";
  timezone = "America/New_York";
  displayManager = "sddm";
  desktopEnvironment = "plasma6";
};
```

### VM Configuration

```nix
# Add to your configuration
{ config, ... }: {
  imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];
  services.qemuGuest.enable = true;
}
```

### Troubleshooting

- **Display issues**: Check `journalctl -b -u display-manager`
- **Boot problems**: Ensure UEFI is enabled in Proxmox
- **Performance**: Enable nested virtualization if needed

## macOS

### Development Shells

```bash
# macOS-specific development shell
nix develop .#macos

# Or use the default shell
nix develop
```

### Available Tools

- **Development**: Xcode tools, Homebrew compatibility
- **Terminal**: iTerm2 integration, macOS-specific utilities
- **Package management**: Nix packages, Homebrew packages

## Windows (WSL)

### WSL2 Setup

```bash
# Install WSL2 with NixOS
wsl --install -d NixOS

# Or use nix-mox in WSL2
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox
nix develop
```

### Windows Integration

- **File sharing**: Access Windows files via `/mnt/c/`
- **Networking**: Automatic network configuration
- **GUI apps**: Use WSLg for GUI applications

## LXC Containers

### Container Setup

```bash
# Create NixOS container
pct create <VMID> local:vztmpl/nixos-*.tar.xz \
  --ostype unmanaged \
  --features nesting=1 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp
```

### Container Configuration

```nix
# Minimal container config
{ config, ... }: {
  boot.isContainer = true;
  system.stateVersion = "23.11";
}
```

## Cloud Platforms

### AWS/GCP/Azure

```bash
# Use minimal template for cloud instances
cp config/templates/minimal.nix config/nixos/configuration.nix

# Build and deploy
nixos-rebuild switch --flake .#nixos
```

### Docker

```nix
# Container-optimized configuration
pkgs.dockerTools.buildImage {
  name = "nix-mox-app";
  config = { 
    Cmd = [ "${pkgs.nginx}/bin/nginx" "-g" "daemon off;" ]; 
  };
}
```

## Troubleshooting

### Common Issues

- **Network**: Check `networking.networkmanager.enable = true;`
- **Graphics**: Ensure proper drivers for your GPU
- **Audio**: Verify PipeWire configuration
- **Boot**: Check boot loader settings for your platform

### Platform-Specific Logs

```bash
# Proxmox
journalctl -b -u display-manager

# macOS
log show --predicate 'process == "nix"' --last 1h

# Windows/WSL
dmesg | grep -i nix
```

For detailed platform guides, see [docs/archive/](archive/).
