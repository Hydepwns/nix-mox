# Windows Gaming Template

This template provides automated installation and configuration of Steam and Rust on Windows systems, with CI/CD support and monitoring capabilities.

## Features

- Automated Steam and Rust installation
- CI/CD integration
- Performance monitoring
- Error handling and logging
- Configuration management
- Resource monitoring

## Prerequisites

- Windows 10 or later
- Administrator privileges
- 50GB free disk space
- 8GB RAM minimum
- DirectX 11 compatible GPU
- Internet connection

## Installation

1. **Run the installation script**:

   ```powershell
   # Using NuShell
   nu install-steam-rust.nu
   ```

2. **Verify installation**:

   ```powershell
   # Check Steam installation
   Test-Path "C:\Program Files (x86)\Steam\Steam.exe"
   
   # Check Rust installation
   Test-Path "C:\Program Files (x86)\Steam\steamapps\common\Rust"
   ```

3. **Launch the game**:

   ```batch
   run-steam-rust.bat
   ```

## Configuration

The template is configured through the `services.nix-mox.templates.customOptions.windows-gaming` attribute set in your NixOS configuration.

### Example NixOS Configuration

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
      monitoring = {
        enable = true;
        logPath = "C:\\Steam\\logs";
      };
    };
  };
};
```

### Steam Settings

The template configures Steam with:

- Silent installation
- Download optimization

### Rust Settings

Default Rust configuration includes:

- Installation via the configured AppID.

## CI/CD Integration

1. **Environment Setup**:

   ```batch
   set CI=true
   set LOG_LEVEL=debug
   ```

2. **Automated Testing**:
   - Prerequisites check
   - Installation verification
   - Performance testing
   - Resource monitoring

3. **Monitoring**:
   - FPS tracking
   - CPU/GPU usage
   - Memory usage
   - Network performance

## Monitoring

### Performance Metrics

- FPS monitoring
- CPU usage
- GPU usage
- Memory usage
- Network statistics

### Alerts

- Low FPS warning
- High CPU usage
- High GPU usage
- Low memory warning

## Troubleshooting

1. **Installation Issues**:
   - Check administrator privileges
   - Verify disk space
   - Check internet connection
   - Review installation logs

2. **Performance Problems**:
   - Check system requirements
   - Verify graphics drivers
   - Monitor resource usage
   - Adjust graphics settings

3. **CI/CD Issues**:
   - Verify environment variables
   - Check test mode settings
   - Review timeout values
   - Check retry configuration

## Best Practices

1. **System Preparation**:
   - Update Windows
   - Install latest drivers
   - Free up disk space
   - Close background apps

2. **Performance Optimization**:
   - Regular driver updates
   - System maintenance
   - Resource monitoring
   - Settings adjustment

3. **Monitoring**:
   - Regular performance checks
   - Resource usage tracking
   - Error log review
   - System health monitoring

## Security Considerations

1. **Access Control**:
   - Administrator privileges
   - Secure installation paths
   - Protected configuration
   - Safe download sources

2. **Data Protection**:
   - Secure logging
   - Protected settings
   - Safe file handling
   - Secure monitoring

## Support

For issues and support:

1. Check the troubleshooting guide
2. Review the logs
3. Verify system requirements
4. Check for updates
