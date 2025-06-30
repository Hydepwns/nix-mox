# Gaming Shell Documentation

The nix-mox gaming shell provides a comprehensive environment for running Windows games on Linux, with special optimizations for League of Legends and other popular titles.

## Gaming Workstation Setup

nix-mox now provides comprehensive system-level gaming support:

### Quick Setup
```bash
# Run the setup script
nu scripts/setup-gaming-workstation.nu
```

### Configuration Options
```nix
# In your NixOS configuration
services.gaming = {
  enable = true;
  gpu.type = "auto";  # Auto-detect GPU
  performance.enable = true;
  audio.enable = true;
  audio.pipewire = true;
  platforms.steam = true;
  platforms.lutris = true;
  platforms.heroic = true;
};
```

### What's Included
- **GPU Drivers**: Auto-detection and configuration for NVIDIA/AMD/Intel
- **OpenGL/Vulkan**: Complete support with 32-bit compatibility
- **Audio**: PipeWire for low-latency gaming audio
- **Performance**: GameMode, CPU governors, kernel optimizations
- **Gaming Platforms**: Steam, Lutris, Heroic with firewall rules
- **Wine Stack**: Wine, DXVK, VKD3D, Winetricks
- **Monitoring**: MangoHud, htop, glmark2

### Simultaneous Development & Gaming
Your workstation can now run both environments simultaneously:
- Use `nix develop .#development` for development
- Use `nix develop .#gaming` for gaming
- Both can coexist and share system resources

## Quick Start

### Enter the Gaming Shell

```bash
nix develop .#gaming
```

### Quick League of Legends Setup

```bash
# Configure League of Legends Wine prefix
league-setup

# Launch League of Legends (after installation)
league-launch
```

## Available Tools

### Gaming Platforms

- **Steam**: Valve's gaming platform with Proton support
- **Lutris**: Open-source gaming platform with Wine integration
- **Heroic**: Epic Games Store and GOG launcher

### Wine & Compatibility

- **Wine**: Windows compatibility layer (v10.0)
- **Winetricks**: Wine configuration utility
- **DXVK**: DirectX 11/10/9 to Vulkan translation (v2.6.1)
- **VKD3D**: DirectX 12 to Vulkan translation
- **Protontricks**: Configure Proton games

### Performance Tools

- **MangoHud**: FPS and system monitoring overlay
- **GameMode**: CPU/GPU performance optimization
- **Mesa**: OpenGL implementation
- **Vulkan Tools**: Vulkan development and debugging

### System Monitoring

- **htop**: Interactive process viewer
- **glmark2**: OpenGL benchmark

### Additional Tools

- **DOSBox**: DOS emulator
- **ScummVM**: Point-and-click adventure game engine

## League of Legends Setup

### Automatic Setup

The gaming shell includes an automated setup script for League of Legends:

```bash
# Run the setup script
league-setup
```

This script will:

1. Create a dedicated Wine prefix (`~/.wine-league`)
2. Install required components (DirectX, Visual C++, etc.)
3. Configure optimal Wine settings
4. Set up environment variables for performance
5. Create launch scripts and Lutris configuration
6. Perform system requirement checks
7. Set up cache directories

### Manual Setup

If you prefer manual setup:

```bash
# Set environment variables
export WINEPREFIX=~/.wine-league
export WINEARCH=win64

# Create Wine prefix
wineboot -i

# Install required components
winetricks -q d3dx9 vcrun2019 dxvk vkd3d xact xact_x64

# Configure Wine settings
winetricks settings win7
winetricks -q ddr=opengl
winetricks -q videomemorysize=4096
```

### Installation via Lutris

1. Launch Lutris: `lutris`
2. Search for "League of Legends"
3. Install using the official installer
4. Configure the game to use the `~/.wine-league` prefix
5. Enable DXVK, VKD3D, GameMode, and MangoHud

### Launching League of Legends

#### Quick Launch

```bash
league-launch
```

#### Manual Launch

```bash
# Source environment variables
source ~/.config/league-env

# Launch with performance optimizations
gamemoderun mangohud wine LeagueClient.exe
```

#### Launch with Monitoring

```bash
# Launch with FPS monitoring
mangohud wine LeagueClient.exe

# Launch with performance optimization
gamemoderun wine LeagueClient.exe

# Launch with both
gamemoderun mangohud wine LeagueClient.exe
```

## Performance Optimization

### Environment Variables

The gaming shell automatically sets these environment variables:

```bash
# DXVK optimizations
export DXVK_HUD=1                    # Show DXVK HUD
export DXVK_STATE_CACHE=1            # Enable state cache
export DXVK_STATE_CACHE_PATH=~/.cache/dxvk

# OpenGL optimizations
export __GL_SHADER_DISK_CACHE=1      # Enable shader cache
export __GL_SHADER_DISK_CACHE_PATH=~/.cache/gl-shaders
export __GL_SYNC_TO_VBLANK=0         # Disable vsync
export __GL_THREADED_OPTIMIZATIONS=1 # Enable threaded optimizations

# Mesa overrides
export MESA_GL_VERSION_OVERRIDE=4.5
export MESA_GLSL_VERSION_OVERRIDE=450

# Audio settings
export PULSE_LATENCY_MSEC=60

# Wine optimizations
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mshtml,mscoree="
```

### GameMode Configuration

GameMode optimizes CPU and GPU performance during gaming:

```bash
# Enable GameMode
gamemode

# Run application with GameMode
gamemoderun <command>
```

### MangoHud Configuration

MangoHud provides FPS and system monitoring:

```bash
# Basic usage
mangohud <command>

# With dlsym hooking
mangohud --dlsym <command>

# Custom configuration
MANGOHUD_CONFIG="fps_limit=60,no_display" mangohud <command>
```

## General Wine Gaming Setup

### Quick Setup Scripts

From the gaming shell, you can use these helper scripts:

```bash
# General Wine gaming configuration
wine-setup

# League of Legends-specific Wine prefix setup
league-setup
```

### Wine Configuration

```bash
# Set up a 64-bit Wine prefix
WINEPREFIX=~/.wine winecfg

# Install required components
winetricks d3dx9 vcrun2019 vcrun2017 vcrun2015 vcrun2013 vcrun2010 vcrun2008 vcrun2005

# Install audio components
winetricks xact xact_x64

# Install graphics components
winetricks dxvk vkd3d

# Configure Wine settings
winetricks settings win7
winetricks ddr=opengl
winetricks videomemorysize=4096
```

## Quick Wine and League of Legends Setup Scripts

From the gaming shell (`nix develop .#gaming`), you can use these helper scripts:

```bash
# General Wine gaming configuration
nix run .#configure-wine

# League of Legends-specific Wine prefix setup
bash devshells/gaming/scripts/configure-league.sh
```

- `configure-wine` sets up a general Wine prefix with optimal settings for gaming.
- `configure-league.sh` creates a dedicated Wine prefix for League of Legends with all required components.

## Troubleshooting

### Common Issues

#### Wine Not Found

```bash
# Ensure you're in the gaming shell
nix develop .#gaming

# Check if wine is available
which wine
```

#### Low Performance

```bash
# Check if GameMode is working
gamemode

# Monitor system resources
htop

# Check graphics performance
glmark2
```

#### Audio Issues

```bash
# Check audio configuration
winetricks -q sound=pulse

# Test audio
winecfg  # Audio tab

# Install audio components
winetricks xact xact_x64
```

#### Graphics Issues

```bash
# Check OpenGL support
glxinfo | grep "OpenGL version"

# Check Vulkan support
vulkaninfo

# Test graphics performance
glmark2

# Install graphics components
winetricks dxvk vkd3d
```

#### Game Crashes

```bash
# Check Wine logs
WINEPREFIX=~/.wine wine --debug

# Verify DXVK installation
winetricks dxvk

# Update Wine
winetricks --self-update
```

### Wine/Gaming Issues

**Problem:** Wine prefix architecture mismatch

```bash
# Error: "64-bit installation, it cannot be used with a 32-bit wineserver"
```

**Solution:**

```bash
# Remove existing prefix and recreate as 32-bit
rm -rf ~/.wine-league
export WINEPREFIX=~/.wine-league
export WINEARCH=win32
wineboot -i
```

**Problem:** League of Legends installer not found

```bash
# Error: "failed to open LeagueInstaller.exe"
```

**Solution:**

1. Download from [Riot Games](https://signup.leagueoflegends.com/en-us/download/)
2. Place in `~/Downloads/` directory
3. Run: `wine ~/Downloads/LeagueInstaller.exe`

### Debugging

#### Enable Wine Debugging

```bash
export WINEDEBUG=+all
wine <application>
```

#### Check DXVK Status

```bash
# Enable DXVK HUD
export DXVK_HUD=1
wine <application>
```

#### Monitor System Resources

```bash
# CPU and memory
htop

# GPU (NVIDIA)
nvidia-smi

# GPU (AMD/Intel)
radeontop  # AMD
intel_gpu_top  # Intel
```

### Gaming Performance

```bash
# Enable GameMode for CPU/GPU optimization
gamemoderun mangohud wine LeagueClient.exe

# Monitor performance
mangohud --dlsym

# Check Vulkan support
vulkaninfo
```

## Advanced Configuration

### Custom Wine Prefixes

Create custom Wine prefixes for different games:

```bash
# Create prefix for specific game
export WINEPREFIX=~/.wine-game-name
export WINEARCH=win64
wineboot -i

# Install game-specific components
winetricks -q <components>
```

### Lutris Integration

Configure Lutris to use the gaming shell environment:

1. Open Lutris
2. Go to Preferences → System Options
3. Set Wine prefix to `~/.wine-league`
4. Enable DXVK, VKD3D, GameMode, and MangoHud
5. Set environment variables as needed

### Steam Proton

Configure Steam to use the gaming shell tools:

1. Open Steam
2. Go to Settings → Steam Play
3. Enable Steam Play for supported titles
4. Enable Steam Play for all other titles
5. Set custom Proton version if needed

## File Locations

### Wine Prefixes

- League of Legends: `~/.wine-league`
- General gaming: `~/.wine`

### Configuration Files

- Environment variables: `~/.config/league-env`
- Launch script: `~/.local/bin/league-launch`
- Lutris config: `~/.config/lutris/games/league-of-legends.yml`
- Wine environment: `~/.config/wine-env`

### Cache Directories

- DXVK cache: `~/.cache/dxvk`
- Shader cache: `~/.cache/gl-shaders`

## Commands Reference

### Quick Commands

```bash
league-setup          # Configure League of Legends
wine-setup            # Configure general Wine prefix
gaming-help           # Show help menu
gaming-test           # Test gaming shell setup
which-shell           # Show current shell
```

### Performance Commands

```bash
gamemoderun <cmd>     # Run with GameMode
mangohud <cmd>        # Run with MangoHud
gamemoderun mangohud <cmd>  # Run with both
```

### Monitoring Commands

```bash
htop                  # Process monitoring
glmark2               # OpenGL benchmark
vulkaninfo            # Vulkan information
glxinfo               # OpenGL information
```

### Wine Commands

```bash
wine <app>            # Run Windows application
winetricks <component> # Install Wine component
winecfg               # Wine configuration
wineserver -k         # Kill Wine server
```

## Maintenance

### Regular Updates

```bash
# Update Nix packages
nix flake update

# Update Wine components
winetricks --self-update
```

### Backup

```bash
# Backup Wine prefix
tar -czf wine-prefix-backup.tar.gz ~/.wine

# Restore Wine prefix
tar -xzf wine-prefix-backup.tar.gz
```

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Ensure you're running the latest version of nix-mox
3. Check system requirements and compatibility
4. Review Wine and Lutris documentation

## Additional Resources

- [WineHQ](https://www.winehq.org/)
- [Lutris Documentation](https://github.com/lutris/lutris/wiki)
- [DXVK GitHub](https://github.com/doitsujin/dxvk)
- [MangoHud GitHub](https://github.com/flightlessmango/MangoHud)
- [GameMode GitHub](https://github.com/FeralInteractive/gamemode)

## Contributing

To improve the gaming shell:

1. Test with different games and configurations
2. Report issues with specific error messages
3. Suggest new tools or optimizations
4. Update documentation for new features

## System Integration: Adding Gaming Features to Your Existing NixOS Configuration

You can import nix-mox's gaming features into your own `/etc/nixos/configuration.nix` without replacing your entire system configuration.

### Step-by-Step Integration

1. **Copy the Gaming Features Module**

   If you have a reusable module (like `gaming-features.nix` or `config/nixos/gaming.nix`), copy it to your system config directory:
   ```bash
   sudo cp /path/to/nix-mox/config/nixos/gaming.nix /etc/nixos/
   ```

2. **Import the Module in Your Configuration**

   Edit `/etc/nixos/configuration.nix` and add the import:
   ```nix
   {
     imports = [
       ./gaming.nix
     ];

     # ...your existing config...
   }
   ```

3. **Enable Gaming Features**

   Add or update the gaming block in your configuration:
   ```nix
   services.gaming = {
     enable = true;
     gpu.type = "auto";  # or "nvidia", "amd", "intel"
     performance.enable = true;
     audio.enable = true;
     audio.pipewire = true;
     platforms.steam = true;
     platforms.lutris = true;
     platforms.heroic = true;
   };
   ```

4. **Test and Apply**

   ```bash
   sudo nixos-rebuild dry-activate --flake /etc/nixos#nixos
   sudo nixos-rebuild switch --flake /etc/nixos#nixos
   ```

### What's Included

- GPU drivers and auto-detection
- Vulkan/OpenGL with 32-bit support
- PipeWire audio and real-time scheduling
- GameMode, MangoHud, and performance tweaks
- Steam, Lutris, Heroic, Wine, DXVK, VKD3D, and more
- Firewall rules for gaming platforms

### Troubleshooting

- If you see errors about deprecated or missing options, update your NixOS channel and check the [troubleshooting guide](./gaming-troubleshooting.md).
- For advanced configuration, see the comments in `gaming.nix` or the [Advanced Configuration](#advanced-configuration) section above.
