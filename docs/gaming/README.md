# Gaming Setup Guide

## Overview

This guide covers the setup and configuration of gaming tools and games in the nix-mox environment, with a focus on Windows games running through Wine/Lutris.

## Available Shells

```bash
# Enter the gaming shell
nix develop .#gaming
```

## Quick Setup Scripts

From the gaming shell (`nix develop .#gaming`), you can use these helper scripts:

```bash
# General Wine gaming configuration
nix run .#configure-wine

# League of Legends-specific Wine prefix setup
bash devshells/gaming/scripts/configure-league.sh
```

- `configure-wine` sets up a general Wine prefix with optimal settings for gaming.
- `configure-league.sh` creates a dedicated Wine prefix for League of Legends with all required components.

## Tools Overview

### Steam

- Full Steam client support
- Native Linux games
- Proton for Windows games

### Lutris

- Game manager and launcher
- Wine configuration management
- Game-specific optimizations

### Wine

- Windows compatibility layer
- DirectX support through DXVK/VKD3D
- 32-bit and 64-bit application support

### Performance Tools

- MangoHud: FPS counter and performance monitoring
- GameMode: System optimization for gaming
- DXVK: DirectX 11 implementation
- VKD3D: DirectX 12 implementation

## League of Legends Setup

### Installation

1. Enter the gaming shell:

   ```bash
   nix develop .#gaming
   ```

2. Launch Lutris:

   ```bash
   lutris
   ```

3. Add League of Legends:
   - Click "+" to add new game
   - Select "Install a Windows game from an executable"
   - Download the League of Legends installer
   - Follow the installation wizard

### Recommended Configuration

1. Wine Configuration:

   ```bash
   # Set up a 64-bit Wine prefix
   WINEPREFIX=~/.wine winecfg
   
   # Install required components
   winetricks d3dx9 vcrun2019 vcrun2017 vcrun2015 vcrun2013 vcrun2010 vcrun2008 vcrun2005
   ```

2. Performance Settings:

   ```bash
   # Run with MangoHud for FPS monitoring
   mangohud lutris
   
   # Run with GameMode for system optimization
   gamemode lutris
   ```

3. Graphics Settings:
   - Enable DXVK for DirectX 11 support
   - Enable VKD3D for DirectX 12 support
   - Use Vulkan renderer if available

### Troubleshooting

1. **Game Crashes**:
   - Check Wine logs: `WINEPREFIX=~/.wine wine --debug`
   - Verify DXVK installation: `winetricks dxvk`
   - Update Wine: `winetricks --self-update`

2. **Performance Issues**:
   - Monitor FPS with MangoHud
   - Check system resource usage
   - Verify GameMode is active
   - Adjust in-game graphics settings

3. **Audio Problems**:
   - Install audio components: `winetricks xact xact_x64`
   - Check PulseAudio configuration
   - Verify Wine audio settings

4. **Network Issues**:
   - Check firewall settings
   - Verify Wine network configuration
   - Test network connectivity

### Performance Optimization

1. **System Settings**:

   ```bash
   # Enable GameMode
   gamemode
   
   # Monitor performance
   mangohud
   ```

2. **Wine Configuration**:

   ```bash
   # Optimize Wine prefix
   WINEPREFIX=~/.wine winetricks settings win7
   
   # Install performance components
   winetricks dxvk vkd3d
   ```

3. **Graphics Settings**:
   - Use Vulkan renderer
   - Enable DXVK
   - Enable VKD3D
   - Adjust in-game settings

## Common Issues

### Game-Specific Issues

1. **League of Legends**:
   - Anti-cheat compatibility
   - Client performance
   - Network connectivity
   - Audio configuration

2. **Steam Games**:
   - Proton compatibility
   - Controller support
   - Cloud saves
   - Workshop content

### System Issues

1. **Graphics**:
   - Driver compatibility
   - Vulkan support
   - DirectX translation
   - Resolution scaling

2. **Audio**:
   - PulseAudio configuration
   - Wine audio components
   - Surround sound support
   - Voice chat

3. **Input**:
   - Controller support
   - Mouse acceleration
   - Keyboard mapping
   - Gamepad configuration

## Maintenance

### Regular Updates

1. **System Updates**:

   ```bash
   # Update Nix packages
   nix flake update
   
   # Update Wine components
   winetricks --self-update
   ```

2. **Game Updates**:
   - Keep games updated through their respective clients
   - Update Wine prefixes when needed
   - Check for DXVK/VKD3D updates

### Backup

1. **Wine Prefixes**:

   ```bash
   # Backup Wine prefix
   tar -czf wine-prefix-backup.tar.gz ~/.wine
   
   # Restore Wine prefix
   tar -xzf wine-prefix-backup.tar.gz
   ```

2. **Game Data**:
   - Backup save files
   - Export game configurations
   - Document custom settings

## Additional Resources

- [WineHQ](https://www.winehq.org/)
- [Lutris Documentation](https://github.com/lutris/lutris/wiki)
- [DXVK GitHub](https://github.com/doitsujin/dxvk)
- [MangoHud GitHub](https://github.com/flightlessmango/MangoHud)
- [GameMode GitHub](https://github.com/FeralInteractive/gamemode)

> **See also:** [Hardware Drivers Guide](../guides/drivers.md) for GPU and driver setup for gaming.
