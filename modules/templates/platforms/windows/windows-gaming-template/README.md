# Windows Gaming Template

Automated installation and configuration of Steam and Rust on Windows systems.

## Prerequisites

- Windows 10 or later
- Administrator privileges
- 50GB free disk space
- 8GB RAM minimum
- DirectX 11 compatible GPU
- Internet connection

## Quick Start

1. Run the installation script:

   ```powershell
   nu install-steam-rust.nu
   ```

2. Launch the game:

   ```batch
   run-steam-rust.bat
   ```

## Configuration

Configure through `services.nix-mox.templates.customOptions.windows-gaming` in your NixOS configuration:

```nix
services.nix-mox.templates = {
  enable = true;
  templates = [ "windows-gaming" ];
  customOptions = {
    windows-gaming = {
      steam = {
        installPath = "C:\\Steam";
      };
      rust = {
        installPath = "C:\\Steam\\steamapps\\common\\Rust";
      };
    };
  };
};
```

## Features

- Automated Steam and Rust installation
- Silent installation mode
- Download optimization
- Performance monitoring
- Error handling and logging

## Troubleshooting

1. **Installation Issues**:
   - Verify administrator privileges
   - Check disk space (50GB minimum)
   - Ensure internet connection
   - Review installation logs

2. **Performance Problems**:
   - Update graphics drivers
   - Check system requirements
   - Monitor resource usage
   - Adjust graphics settings

## Support

For issues:

1. Check the troubleshooting guide
2. Review the logs
3. Verify system requirements
