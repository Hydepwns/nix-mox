# Gaming Troubleshooting Guide

This guide helps you diagnose and fix common gaming issues in nix-mox.

## Quick Diagnostics

### Run Automated Diagnostics
```bash
# Validate your gaming configuration
make gaming-validate

# Run performance benchmark
make gaming-benchmark

# Test gaming setup
make gaming-test
```

## Common Issues & Solutions

### 1. Graphics Issues

#### Problem: Black Screen or No Display
**Symptoms:** Screen goes black after boot, no graphics output

**Solutions:**
```bash
# Check GPU detection
lspci | grep -i vga

# Check driver status
nvidia-smi  # For NVIDIA
radeontop   # For AMD

# Check X11 logs
journalctl -b -p err | grep -i x11

# Verify OpenGL support
glxinfo | grep "OpenGL version"
```

**Configuration Fix:**
```nix
# In your NixOS configuration
services.gaming = {
  enable = true;
  gpu.type = "nvidia";  # or "amd", "intel"
};
```

#### Problem: Low FPS or Poor Performance
**Symptoms:** Games run slowly, stuttering, low frame rates

**Solutions:**
```bash
# Check CPU governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set performance governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check GameMode status
gamemoded -s

# Monitor performance with MangoHud
mangohud /usr/bin/glmark2
```

**Configuration Fix:**
```nix
services.gaming = {
  enable = true;
  performance = {
    enable = true;
    gameMode = true;
    cpuGovernor = "performance";
  };
};
```

### 2. Audio Issues

#### Problem: No Sound in Games
**Symptoms:** Games have no audio, audio system not detected

**Solutions:**
```bash
# Check audio system
pactl info

# Check PipeWire status
pw-top

# Test audio
speaker-test -c 2 -t sine -f 1000

# Check audio devices
pactl list short sinks
```

**Configuration Fix:**
```nix
services.gaming = {
  enable = true;
  audio = {
    enable = true;
    pipewire = true;
    lowLatency = true;
  };
};
```

#### Problem: Audio Latency
**Symptoms:** Audio delay, crackling, poor audio quality

**Solutions:**
```bash
# Check PipeWire configuration
pw-top --once

# Adjust buffer size
pactl set-port-latency-offset alsa_output.pci-0000_00_1f.3.analog-stereo 0

# Check real-time priority
ulimit -r
```

### 3. Wine & Windows Games

#### Problem: Wine Not Working
**Symptoms:** Windows games won't start, Wine errors

**Solutions:**
```bash
# Check Wine version
wine --version

# Test Wine
winecfg

# Check Wine prefix
ls ~/.wine

# Reset Wine prefix
rm -rf ~/.wine
winecfg
```

**Configuration Fix:**
```nix
# Ensure Wine is properly configured
environment.systemPackages = with pkgs; [
  wine
  winetricks
  dxvk
  vkd3d
];
```

#### Problem: DXVK/VKD3D Issues
**Symptoms:** DirectX games crash, poor performance

**Solutions:**
```bash
# Check DXVK installation
ls /usr/share/dxvk/

# Test Vulkan
vulkaninfo | grep "GPU"

# Check Wine DXVK
WINEDLLOVERRIDES="dxgi,d3d11,d3d10,d3d9=n" wine game.exe
```

### 4. Gaming Platform Issues

#### Problem: Steam Not Working
**Symptoms:** Steam won't start, games won't launch

**Solutions:**
```bash
# Check Steam installation
which steam

# Reset Steam
rm -rf ~/.steam
steam

# Check Steam runtime
steam --reset-runtime

# Verify Steam files
steam --verify-files
```

#### Problem: Lutris Issues
**Symptoms:** Lutris won't install games, configuration errors

**Solutions:**
```bash
# Check Lutris installation
which lutris

# Reset Lutris configuration
rm -rf ~/.config/lutris
rm -rf ~/.local/share/lutris

# Check Wine integration
lutris --list-games
```

### 5. Performance Issues

#### Problem: High CPU Usage
**Symptoms:** System becomes unresponsive, high temperatures

**Solutions:**
```bash
# Monitor CPU usage
htop

# Check thermal throttling
cat /sys/class/thermal/thermal_zone*/temp

# Check CPU frequency
cat /proc/cpuinfo | grep MHz

# Optimize CPU governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

#### Problem: Memory Issues
**Symptoms:** Games crash, system becomes slow

**Solutions:**
```bash
# Check memory usage
free -h

# Check swap usage
swapon --show

# Monitor memory pressure
cat /proc/pressure/memory
```

### 6. Network Issues

#### Problem: Online Gaming Problems
**Symptoms:** High ping, disconnections, NAT issues

**Solutions:**
```bash
# Check network connectivity
ping -c 4 8.8.8.8

# Check gaming ports
ss -tuln | grep -E "(27015|27016|27017)"

# Test port forwarding
nc -zv your-server.com 27015
```

**Configuration Fix:**
```nix
# Open gaming ports
networking.firewall = {
  allowedTCPPorts = [ 27015 27016 27017 27018 27019 27020 ];
  allowedUDPPorts = [ 27015 27016 27017 27018 27019 27020 ];
};
```

## Advanced Troubleshooting

### System Logs
```bash
# Check system logs for errors
journalctl -b -p err

# Check X11 logs
journalctl -b | grep -i x11

# Check audio logs
journalctl -b | grep -i audio
journalctl -b | grep -i pipewire
```

### Performance Profiling
```bash
# Profile system performance
perf record -g -p $(pgrep -f game)

# Monitor GPU usage
nvidia-smi -l 1  # For NVIDIA
radeontop        # For AMD

# Monitor disk I/O
iotop
```

### Debug Mode
```bash
# Enable debug logging
export WINEDEBUG=+all
export DXVK_HUD=1
export MANGOHUD=1

# Run game with debug info
mangohud wine game.exe
```

## Getting Help

### Before Asking for Help
1. Run `make gaming-validate` and include the output
2. Run `make gaming-benchmark` and include the results
3. Check system logs for errors
4. Note your hardware configuration
5. Describe the exact steps to reproduce the issue

### Useful Commands for Bug Reports
```bash
# System information
nixos-version
lscpu
free -h
lspci | grep -i vga

# Gaming configuration
nixos-option services.gaming

# Performance baseline
glmark2 --fullscreen
vulkaninfo | grep "GPU"
```

### Community Resources
- [nix-mox Issues](https://github.com/Hydepwns/nix-mox/issues)
- [NixOS Gaming Wiki](https://nixos.wiki/wiki/Gaming)
- [Lutris Documentation](https://github.com/lutris/lutris/wiki)
- [Wine AppDB](https://appdb.winehq.org/)

## Prevention

### Regular Maintenance
```bash
# Weekly maintenance
make gaming-validate
make gaming-benchmark

# Update gaming tools
nix flake update
nixos-rebuild switch

# Clean up old Wine prefixes
find ~/.wine -name "*.exe" -mtime +30 -delete
```

### Best Practices
1. **Keep system updated** with `nixos-rebuild switch`
2. **Monitor performance** regularly with benchmarks
3. **Use GameMode** for automatic optimization
4. **Configure proper audio** with PipeWire
5. **Maintain Wine prefixes** and clean up regularly
6. **Monitor system resources** during gaming sessions

For more detailed information, see the [Gaming Guide](gaming.md) and [Architecture Documentation](../architecture/ARCHITECTURE.md). 