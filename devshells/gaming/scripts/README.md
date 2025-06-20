# Gaming Scripts

This directory contains scripts for gaming setup and management in the nix-mox framework.

## Available Scripts

### `configure-league.sh`

**Purpose**: Configure Wine prefix for League of Legends
**Usage**: `./configure-league.sh`
**Requirements**:

- Wine 10.0+ installed
- winetricks available
- Internet connection for downloading components

**What it does**:

- Creates 64-bit Wine prefix at `~/.wine-league`
- Installs DirectX 9 components (d3dx9)
- Installs Visual C++ runtimes (vcrun2019, vcrun2017, vcrun2015)
- Installs DXVK and VKD3D for graphics compatibility
- Installs XACT for audio support
- Sets Windows 7 compatibility mode
- Installs .NET Framework 4.8
- Installs core fonts

### `launch-league.sh`

**Purpose**: Launch League of Legends with optimal performance settings
**Usage**: `./launch-league.sh` or `league-launch` (alias)
**Requirements**:

- League of Legends installed in Wine prefix
- Gaming devshell environment
- GameMode and MangoHud available

**What it does**:

- Sets Wine environment variables (WINEPREFIX, WINEARCH)
- Configures performance environment variables (DXVK, OpenGL)
- Checks if League of Legends is installed
- Launches with GameMode and MangoHud for optimal performance

### `test-gaming.sh`

**Purpose**: Test gaming shell setup and components
**Usage**: `./test-gaming.sh` or `gaming-test` (alias)
**Requirements**: Gaming devshell environment

**What it does**:

- Tests Wine installation and version
- Tests DXVK and VKD3D availability
- Tests GameMode functionality
- Tests MangoHud setup
- Tests Vulkan support
- Tests audio system
- Provides performance benchmarks

### `configure-wine.nix`

**Purpose**: Nix package for Wine configuration utilities
**Usage**: Used internally by the gaming devshell
**Requirements**: Nix build environment

## Quick Start

1. **Enter the gaming shell**:

   ```bash
   nix develop .#gaming
   ```

2. **Configure League of Legends**:

   ```bash
   league-setup
   ```

3. **Install League of Legends**:
   - Download installer from <https://na.leagueoflegends.com/>
   - Run: `wine64 League_of_Legends_installer.exe`

4. **Launch League of Legends**:

   ```bash
   league-launch
   ```

## Troubleshooting

### Common Issues

**Wine prefix architecture mismatch**:

- Ensure you're using 64-bit Wine: `wine64 --version`
- Recreate prefix: `rm -rf ~/.wine-league && league-setup`

**Missing components**:

- Run `league-setup` to install all required components
- Check internet connection for downloads

**Performance issues**:

- Ensure GameMode is working: `gamemode --version`
- Check MangoHud: `mangohud --version`
- Verify DXVK: `echo $DXVK_HUD`

**Graphics issues**:

- Check Vulkan support: `vulkaninfo`
- Verify DXVK installation in Wine prefix
- Try different Windows compatibility modes

### Getting Help

- Type `gaming-help` in the gaming shell for detailed information
- Check the main nix-mox documentation
- Review script output for specific error messages

## Environment Variables

The gaming shell sets these environment variables for optimal performance:

- `DXVK_HUD=1` - Show DXVK performance overlay
- `DXVK_STATE_CACHE=1` - Enable DXVK state caching
- `__GL_SHADER_DISK_CACHE=1` - Enable OpenGL shader caching
- `__GL_SYNC_TO_VBLANK=0` - Disable vsync for better performance
- `__GL_THREADED_OPTIMIZATIONS=1` - Enable threaded optimizations
