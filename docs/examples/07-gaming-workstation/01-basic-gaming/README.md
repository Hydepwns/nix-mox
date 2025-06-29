# Basic Gaming Setup

This example demonstrates the simplest way to enable gaming support in nix-mox with automatic hardware detection and basic optimizations.

## What This Example Does

- **Auto-detects your GPU** (NVIDIA, AMD, or Intel)
- **Enables OpenGL/Vulkan support** with 32-bit compatibility
- **Configures basic performance optimizations**
- **Sets up audio support** with PipeWire
- **Provides a foundation** for gaming applications

## Usage

### 1. Copy the Configuration

Copy `configuration.nix` to your NixOS configuration directory:

```bash
cp configuration.nix /etc/nixos/
```

### 2. Apply the Configuration

```bash
sudo nixos-rebuild switch
```

### 3. Test the Setup

```bash
# Run the setup script
nu scripts/setup-gaming-workstation.nu

# Enter gaming shell
nix develop .#gaming

# Test graphics
glxinfo | grep "OpenGL version"
vulkaninfo | grep "GPU"

# Test audio
speaker-test -c 2 -t sine -f 1000
```

## What Gets Configured

### GPU Support
- **NVIDIA**: Enables NVIDIA drivers with modesetting
- **AMD**: Enables AMDVLK and Mesa drivers
- **Intel**: Enables Intel media drivers and VA-API

### Graphics APIs
- OpenGL 4.x support
- Vulkan support
- 32-bit compatibility layers
- Hardware acceleration

### Performance
- Basic CPU governor optimization
- Memory management improvements
- Kernel parameter tuning

### Audio
- PipeWire audio system
- Low-latency configuration
- ALSA compatibility

## Next Steps

After applying this basic configuration, you can:

1. **Install gaming platforms**:
   ```bash
   nix develop .#gaming
   steam
   ```

2. **Add performance monitoring**:
   ```bash
   mangohud /usr/bin/glmark2
   ```

3. **Configure specific platforms**:
   - See [Multi-Platform Gaming](../05-multi-platform/) example
   - See [Performance Tuning](../03-performance-tuning/) example

## Troubleshooting

### GPU Not Detected
```bash
# Check what GPU is detected
lspci | grep -i vga

# Check driver status
nvidia-smi  # For NVIDIA
radeontop   # For AMD
```

### Graphics Issues
```bash
# Check OpenGL support
glxinfo | grep "OpenGL version"

# Check Vulkan support
vulkaninfo | grep "GPU"
```

### Audio Issues
```bash
# Check audio system
pactl info
pw-top
```

## Configuration Options

This basic example uses these default settings:

```nix
services.gaming = {
  enable = true;
  gpu.type = "auto";           # Auto-detect GPU
  performance.enable = true;    # Basic performance
  audio.enable = true;         # Audio support
};
```

For more advanced options, see the other examples in this directory. 