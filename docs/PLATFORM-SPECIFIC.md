# Platform-Specific Features

This document describes the platform-specific features available in nix-mox, including packages, development shells, and tools that are tailored for different operating systems and architectures.

## Overview

nix-mox provides comprehensive platform-specific support for:

- **Linux** (x86_64-linux, aarch64-linux)
- **macOS** (x86_64-darwin, aarch64-darwin)
- **Windows** (via WSL or cross-compilation)

## Platform Detection

The framework automatically detects your platform and provides appropriate tools and packages. You can check your platform information using:

```bash
# In any nix-mox shell
platform-info
```

Or check the environment variables:

```bash
echo $NIX_MOX_PLATFORM
echo $NIX_MOX_IS_LINUX
echo $NIX_MOX_IS_DARWIN
echo $NIX_MOX_ARCH
```

## Linux-Specific Features

### Available Packages

Linux systems have access to the following packages:

```bash
# System management
nix run .#proxmox-update         # Update Proxmox systems
nix run .#vzdump-backup          # Backup VMs with vzdump
nix run .#zfs-snapshot           # Manage ZFS snapshots
nix run .#nixos-flake-update     # Update NixOS flakes

# Installation and setup
nix run .#install                # Install nix-mox
nix run .#uninstall              # Uninstall nix-mox
nix run .#remote-builder-setup   # Setup remote Nix builders
nix run .#test-remote-builder    # Test remote builder connectivity
```

### Development Shells

```bash
# All platforms
nix develop .#default            # Default development shell
nix develop .#development        # Development tools
nix develop .#testing           # Testing tools
nix develop .#services          # Service management tools
nix develop .#monitoring        # Monitoring tools

# Linux-specific
nix develop .#zfs               # ZFS management tools
nix develop .#gaming            # Gaming tools (x86_64 only)
```

### Linux-Specific Dependencies

The Linux packages include platform-specific dependencies:

- **Common**: bash, coreutils, gawk, gnugrep, gnused, gnutar
- **x86_64**: proxmox-backup-client, qemu, lxc, zfs
- **aarch64**: qemu, lxc, zfs (with architecture-appropriate alternatives)

## macOS-Specific Features

### Available Packages

macOS systems have access to the following packages:

```bash
# System management
nix run .#macos-maintenance     # macOS system maintenance
nix run .#security-audit        # Security audit and checks
nix run .#xcode-setup           # Setup Xcode command line tools

# Package management
nix run .#homebrew-setup        # Setup and manage Homebrew

# Installation and setup
nix run .#install               # Install nix-mox (macOS-specific)
nix run .#uninstall             # Uninstall nix-mox (macOS-specific)
```

### Development Shells

```bash
# All platforms
nix develop .#default           # Default development shell
nix develop .#development       # Development tools
nix develop .#testing          # Testing tools
nix develop .#services         # Service management tools
nix develop .#monitoring       # Monitoring tools

# macOS-specific
nix develop .#macos            # macOS development tools
```

### macOS-Specific Dependencies

The macOS packages include platform-specific dependencies:

- **Common**: bash, coreutils, gawk, gnugrep, gnused, gnutar, curl, jq
- **x86_64**: homebrew, mas
- **aarch64**: homebrew, mas, cocoapods

### Environment Variables

macOS shells automatically set:

```bash
export MACOSX_DEPLOYMENT_TARGET=11.0
export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
```

## Windows/WSL-Specific Features

### Available Packages

Windows/WSL systems have access to the following packages:

```bash
# Installation and setup
nix run .#install               # Install nix-mox (Windows/WSL)
nix run .#uninstall             # Uninstall nix-mox (Windows/WSL)

# Gaming setup
nix run .#install-steam-rust    # Install Steam + Rust (Windows/WSL)
```

### Development Shells

```bash
nix develop .#windows           # Windows/WSL development shell
```

### Windows/WSL-Specific Notes

- **WSL is recommended** for best compatibility with Nix and nix-mox.
- Native Windows support is experimental; use WSL for full features.
- Scripts are provided in both PowerShell and Nushell/Bash where possible.
- Some packages may require additional setup or permissions on Windows.

### Example Scripts

- `scripts/windows/install.ps1`: Install nix-mox on Windows/WSL
- `scripts/windows/uninstall.ps1`: Uninstall nix-mox on Windows/WSL
- `scripts/windows/install-steam-rust.nu`: Install Steam and Rust for gaming

## Platform-Specific Scripts

### Linux Scripts

#### `scripts/linux/install.nu`

- Installs nix-mox on Linux systems
- Checks for Nix installation
- Sets up Linux-specific configurations

#### `scripts/linux/proxmox-update.nu`

- Updates Proxmox systems
- Manages package updates
- Handles system maintenance

#### `scripts/linux/vzdump-backup.nu`

- Creates VM backups using vzdump
- Manages backup retention
- Supports different backup strategies

#### `scripts/linux/zfs-snapshot.nu`

- Manages ZFS snapshots
- Implements snapshot rotation
- Handles snapshot cleanup

### macOS Scripts

#### `scripts/macos/install.nu`

- Installs nix-mox on macOS systems
- Checks for Nix and Homebrew
- Sets up macOS-specific configurations

#### `scripts/macos/homebrew-setup.nu`

- Installs and configures Homebrew
- Sets up common development tools
- Manages Homebrew taps

#### `scripts/macos/macos-maintenance.nu`

- Clears system caches
- Manages Homebrew cleanup
- Checks disk space and system updates

#### `scripts/macos/xcode-setup.nu`

- Installs Xcode command line tools
- Verifies Xcode installation
- Shows available SDKs

#### `scripts/macos/security-audit.nu`

- Checks firewall status
- Verifies Gatekeeper settings
- Audits System Integrity Protection
- Checks FileVault status

## Platform-Specific Tests

### Linux Tests (`scripts/tests/linux/linux-tests.nu`)

- Tests Linux-specific commands
- Verifies ZFS functionality
- Checks systemd availability

### macOS Tests (`scripts/tests/macos/macos-tests.nu`)

- Tests macOS-specific commands
- Verifies Homebrew functionality
- Checks Xcode tools
- Tests security features

### Windows Tests (`scripts/tests/windows/windows-tests.nu`)

- Tests Windows/WSL-specific commands
- Verifies PowerShell, cmd, wsl availability
- Checks Python installation
- Tests Nushell functionality
- Verifies Nix installation

## Architecture-Specific Considerations

### x86_64 (Intel/AMD)

- Full support for all packages
- Gaming tools available on Linux
- Optimized for Intel/AMD processors

### aarch64 (ARM)

- Limited support for some packages
- Architecture-appropriate alternatives
- Optimized for ARM processors (Apple Silicon, Raspberry Pi)

## Cross-Platform Development

### Common Tools

All platforms share these common development tools:

- nushell
- git
- nix
- nixpkgs-fmt
- shellcheck
- coreutils
- fd
- ripgrep
- code-cursor (Cursor AI IDE)
- kitty (Terminal emulator)

### Platform-Specific Tools

Each platform gets additional tools:

- **Linux**: zlib, openssl, systemd tools, qemu, virt-manager, libvirt (Proxmox tools)
- **macOS**: CoreServices, Foundation frameworks

## Error Handling

The framework includes robust error handling for platform-specific features:

1. **Graceful Degradation**: If a platform-specific package isn't available, it's set to `null` rather than causing build failures
2. **Clear Error Messages**: Platform-specific errors include helpful information about what's supported
3. **Fallback Options**: Where possible, alternative implementations are provided

## Best Practices

### For Users

1. Always check platform compatibility before using packages
2. Use the `platform-info` command to verify your environment
3. Read package documentation for platform-specific requirements

### For Developers

1. Test on multiple platforms when possible
2. Use conditional logic for platform-specific features
3. Provide clear error messages for unsupported platforms
4. Document platform-specific requirements

## Troubleshooting

### Common Issues

#### Package Not Found

If a package isn't available on your platform:

```bash
# Check what packages are available
nix flake show .#packages

# Check platform information
platform-info
```

#### Script Execution Errors

If a script fails with platform errors:

```bash
# Check if the script is for your platform
head -n 10 /path/to/script.nu

# Verify platform detection
echo $NIX_MOX_PLATFORM
```

#### Build Failures

If builds fail on specific platforms:

```bash
# Check the flake for platform-specific logic
grep -r "stdenv.isLinux\|stdenv.isDarwin" flake.nix

# Verify your platform is supported
nix flake show .#devShells
```

## Future Enhancements

Planned platform-specific features:

- **Windows Support**: Full Windows support via WSL or native tools
- **Container Support**: Platform-specific container configurations
- **Cloud Integration**: Platform-specific cloud deployment tools
- **Mobile Support**: iOS/Android development tools (macOS)

## Contributing

When adding platform-specific features:

1. Follow the existing patterns in the codebase
2. Add appropriate tests for each platform
3. Update this documentation
4. Test on multiple platforms when possible
5. Include clear error messages for unsupported platforms

For more information, see the [Contributing Guide](CONTRIBUTING.md).
