# Gaming Workstation Examples

This directory contains examples for configuring gaming workstations with nix-mox, demonstrating both basic and advanced gaming configurations.

## Examples Overview

### 1. [Basic Gaming Setup](01-basic-gaming/)
Simple gaming configuration with automatic GPU detection and basic optimizations.

### 2. [Custom GPU Configuration](02-custom-gpu/)
Manual GPU driver configuration for specific hardware requirements.

### 3. [Performance Tuning](03-performance-tuning/)
Advanced performance optimization examples including GameMode and kernel tuning.

### 4. [Development + Gaming](04-development-gaming/)
Combined development and gaming environments for dual-purpose workstations.

### 5. [Multi-Platform Gaming](05-multi-platform/)
Configuration for Steam, Lutris, Heroic, and other gaming platforms.

### 6. [Audio Optimization](06-audio-optimization/)
Low-latency audio setup specifically optimized for gaming.

## Quick Start

### Basic Gaming Configuration

```nix
# configuration.nix
{ config, pkgs, ... }:

{
  imports = [ ./gaming.nix ];
  
  services.gaming = {
    enable = true;
    gpu.type = "auto";  # Auto-detect GPU
    performance.enable = true;
    audio.enable = true;
  };
}
```

### Setup Commands

```bash
# Run the setup script
nu scripts/setup-gaming-workstation.nu

# Enter gaming shell
nix develop .#gaming

# Test gaming setup
./devshells/gaming/scripts/test-gaming.sh
```

## Features Demonstrated

### System-Level Optimizations
- **GPU Auto-Detection**: Automatic detection and configuration of NVIDIA/AMD/Intel GPUs
- **OpenGL/Vulkan Support**: Complete graphics API support with 32-bit compatibility
- **Audio Optimization**: PipeWire with low-latency configuration
- **Performance Tuning**: GameMode, CPU governors, kernel optimizations

### Gaming Platform Support
- **Steam**: Native Linux gaming platform
- **Lutris**: Universal gaming platform for Windows games
- **Heroic**: Epic Games Store and GOG integration
- **Wine Stack**: Wine, DXVK, VKD3D, Winetricks

### Development Integration
- **Simultaneous Environments**: Run development and gaming shells together
- **Shared Resources**: Optimized system configuration benefits both environments
- **Performance Monitoring**: MangoHud, htop, glmark2 for system monitoring

## Hardware Requirements

### Minimum Requirements
- **GPU**: Any modern GPU with OpenGL 4.0+ support
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB free space for gaming platforms
- **Audio**: Any audio device with ALSA/PipeWire support

### Recommended Requirements
- **GPU**: NVIDIA GTX 1060+ or AMD RX 580+
- **RAM**: 32GB for development + gaming
- **Storage**: NVMe SSD with 100GB+ free space
- **Audio**: Low-latency audio interface

## Troubleshooting

### Common Issues

1. **GPU Not Detected**
   ```bash
   # Check GPU detection
   lspci | grep -i vga
   nvidia-smi  # For NVIDIA
   radeontop   # For AMD
   ```

2. **Audio Issues**
   ```bash
   # Check audio configuration
   pactl info
   pw-top
   ```

3. **Performance Problems**
   ```bash
   # Check performance settings
   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   gamemoded -s
   ```

### Debug Commands

```bash
# Check gaming configuration
nixos-option services.gaming

# Test graphics
glxinfo | grep "OpenGL version"
vulkaninfo | grep "GPU"

# Test audio
speaker-test -c 2 -t sine -f 1000

# Monitor performance
mangohud /usr/bin/glmark2
```

## Advanced Configuration

### Custom GPU Settings

```nix
services.gaming = {
  enable = true;
  gpu = {
    type = "nvidia";
    powerManagement = true;
    modesetting = true;
    nvidiaSettings = true;
  };
};
```

### Performance Optimization

```nix
services.gaming = {
  enable = true;
  performance = {
    enable = true;
    gameMode = true;
    cpuGovernor = "performance";
    kernelOptimizations = true;
  };
};
```

### Audio Configuration

```nix
services.gaming = {
  enable = true;
  audio = {
    enable = true;
    pipewire = true;
    lowLatency = true;
    realtimePriority = true;
  };
};
```

## Integration with Development

The gaming workstation configuration is designed to work alongside development environments:

```bash
# Terminal 1: Development
nix develop .#development
cursor .

# Terminal 2: Gaming
nix develop .#gaming
steam
```

Both environments share the same optimized system configuration while maintaining independent tool sets.

## Contributing

When adding new gaming examples:

1. Follow the existing directory structure
2. Include both basic and advanced configurations
3. Provide clear documentation and troubleshooting steps
4. Test with multiple GPU types when possible
5. Include performance benchmarks where relevant

For more information, see the [Gaming Guide](../../guides/gaming.md) and [Architecture Documentation](../../architecture/ARCHITECTURE.md). 