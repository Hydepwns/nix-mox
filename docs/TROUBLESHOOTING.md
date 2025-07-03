# Troubleshooting

> Quick solutions for common nix-mox issues.

## Common Issues

### Display Problems

```bash
# Check display manager
journalctl -b -u display-manager

# Verify graphics drivers
lspci -k | grep -A 2 -E "(VGA|3D)"

# Test X server
xrandr --listmonitors
```

**Solutions:**

- **No display**: Ensure UEFI is enabled, check boot loader settings
- **Wrong resolution**: Configure in KDE Settings > Display Configuration
- **Driver issues**: Add `services.xserver.videoDrivers = [ "nvidia" ];` for NVIDIA

### Boot Problems

```bash
# Check boot configuration
nixos-rebuild dry-activate --flake .#nixos

# Verify hardware config
cat config/hardware/hardware-configuration-actual.nix
```

**Solutions:**

- **Boot loader warning**: Ensure `systemd-boot` is configured for UEFI
- **Missing hardware**: Run `nixos-generate-config` to detect hardware
- **Rollback**: `sudo nixos-rebuild switch --rollback`

### Network Issues

```bash
# Check network status
systemctl status NetworkManager
ip addr show

# Test connectivity
ping -c 4 8.8.8.8
```

**Solutions:**

- **No internet**: Ensure `networking.networkmanager.enable = true;`
- **WiFi not working**: Check `hardware.wirelessRegulatoryDatabase = true;`
- **DNS issues**: Add `networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];`

### Package/Service Issues

```bash
# Check service status
systemctl status <service-name>

# View service logs
journalctl -u <service-name> -f

# Test configuration
nixos-rebuild dry-activate --flake .#nixos
```

**Solutions:**

- **Service not starting**: Check dependencies and configuration
- **Package not found**: Verify `nixpkgs.config.allowUnfree = true;`
- **Build failures**: Try `nix-collect-garbage -d` to free space

## Gaming Issues

### Steam Problems

```bash
# Check Steam logs
cat ~/.steam/steam/logs/content_log.txt

# Verify Steam installation
which steam
```

**Solutions:**

- **Steam not starting**: Ensure `programs.steam.enable = true;`
- **Game performance**: Check `hardware.opengl.enable = true;`
- **Controller issues**: Add `services.udev.packages = [ pkgs.steam ];`

### Graphics Performance

```bash
# Check GPU usage
nvidia-smi  # NVIDIA
radeontop   # AMD
intel_gpu_top  # Intel
```

**Solutions:**

- **Low FPS**: Enable GameMode, check graphics drivers
- **Screen tearing**: Add `services.xserver.screenSection = "Option \"TearFree\" \"true\"";`
- **VRAM issues**: Check GPU memory allocation

## Development Issues

### Build Failures

```bash
# Check build logs
nix build .#checks.x86_64-linux.unit --verbose

# Update dependencies
nix flake update
```

**Solutions:**

- **Outdated inputs**: Run `nix flake update`
- **Missing dependencies**: Check `environment.systemPackages`
- **Version conflicts**: Update to latest nixpkgs

### Docker Issues

```bash
# Check Docker status
systemctl status docker
docker ps
```

**Solutions:**

- **Docker not starting**: Ensure `virtualisation.docker.enable = true;`
- **Permission denied**: Add user to `docker` group
- **Storage issues**: Check Docker storage configuration

## Quick Fixes

### Reset Configuration

```bash
# Switch to minimal template
cp config/templates/minimal.nix config/nixos/configuration.nix
sudo nixos-rebuild switch --flake .#nixos
```

### Clean Build

```bash
# Clean Nix store
nix-collect-garbage -d

# Rebuild from scratch
sudo nixos-rebuild boot --flake .#nixos
```

### Check System Health

```bash
# Run cleanup script
nu scripts/core/cleanup.nu

# Check disk space
df -h

# Monitor system resources
htop
```

## Getting Help

1. **Check logs**: `journalctl -b -f`
2. **Verify config**: `nixos-rebuild dry-activate --flake .#nixos`
3. **Search issues**: Check GitHub issues for similar problems
4. **Ask community**: NixOS forums, Discord, or GitHub discussions

For detailed troubleshooting, see [docs/archive/guides/TROUBLESHOOTING.md](archive/guides/TROUBLESHOOTING.md).
