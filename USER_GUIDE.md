# Nix-Mox User Guide

## Quick Start

### Prerequisites
- NixOS or Nix with flakes enabled
- Nushell installed
- Git

### Installation
```bash
# Clone the repository
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# Run the unified setup script
nu scripts/setup/unified-setup.nu

# Apply configuration
make chezmoi-apply
```

## Architecture Overview

### Unified Libraries
All scripts use unified libraries for consistent behavior:

- **`scripts/lib/unified-checks.nu`** - Common validation functions
- **`scripts/lib/unified-error-handling.nu`** - Standardized error handling and logging

### Chezmoi Integration
User configurations are managed through Chezmoi for cross-platform compatibility:

- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Template System**: Dynamic configuration based on environment
- **Version Control**: Git-based dotfile management
- **Atomic Updates**: Safe, reversible configuration changes

## Available Commands

### Chezmoi Operations
```bash
make chezmoi-apply      # Apply configuration
make chezmoi-diff       # Show differences
make chezmoi-sync       # Sync with remote repository
make chezmoi-edit       # Edit configuration
make chezmoi-status     # Show status
make chezmoi-verify     # Verify configuration
```

### System Validation
```bash
# Validate NixOS configuration
nu scripts/validation/validate-config.nu

# Pre-rebuild safety check
nu scripts/validation/pre-rebuild-safety-check.nu

# Storage validation
nu scripts/storage/storage-guard.nu
```

### Maintenance
```bash
# System health check
nu scripts/maintenance/health-check.nu

# Cleanup
nu scripts/maintenance/cleanup.nu

# Safe rebuild
nu scripts/maintenance/safe-rebuild.nu
```

### Analysis and Monitoring
```bash
# System dashboard
nu scripts/analysis/dashboard.nu

# Package size analysis
nu scripts/analysis/analyze-sizes.nu

# Performance benchmarks
nu scripts/analysis/benchmarks/gaming-benchmark.nu
```

## Configuration Management

### NixOS Configuration
The main NixOS configuration is in `config/nixos/configuration.nix`. This file contains:
- System-level packages and services
- Hardware configuration
- Security settings
- Network configuration

### User Configuration (Chezmoi)
User-specific configurations are managed through Chezmoi templates:
- Shell configuration (zsh/bash)
- Git configuration
- Editor settings
- User packages
- Environment variables

### Gaming Configuration
Gaming-specific configurations are in `flakes/gaming/`:
- GPU drivers and settings
- Gaming tools (Steam, Lutris, etc.)
- Performance optimizations
- Controller support

## Development Workflow

### Adding New Scripts
When creating new scripts, follow this template:

```nushell
#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-error-handling.nu

def main [] {
    # Your script logic here
    log_info "Starting script execution"
    
    # Use unified functions
    let platform = (check_platform)
    if $platform.is_linux {
        # Linux-specific logic
    }
    
    log_success "Script completed successfully"
}

# Run the main function
main
```

### Error Handling
Use the enhanced error handling library for consistent error reporting:

```nushell
# Safe command execution
let result = (safe_exec "your-command" "context")
if not $result.success {
    log_error $"Command failed: ($result.error)" "context"
    exit 1
}

# Require dependencies
require_command "nix" "script-name"
require_file "config/nixos/configuration.nix" "script-name"
```

### Validation Functions
Use unified validation functions for common checks:

```nushell
# Check if command exists
if (check_command "nix") {
    log_success "Nix is available"
}

# Check file existence
if (check_file "flake.nix") {
    log_success "flake.nix found"
}

# Check system health
let health = (check_system_services)
if $health.healthy {
    log_success "System services healthy"
}
```

## Troubleshooting

### Common Issues

#### Script Import Errors
If you see "Module not found" errors:
```bash
# Check if the script is in the correct directory
ls scripts/lib/

# Verify import paths are correct
# For scripts in scripts/validation/, use: use ../lib/unified-checks.nu
# For scripts in scripts/maintenance/, use: use ../lib/unified-checks.nu
```

#### Chezmoi Configuration Issues
If Chezmoi isn't working correctly:
```bash
# Check Chezmoi status
make chezmoi-status

# Verify configuration
make chezmoi-verify

# Show differences
make chezmoi-diff
```

#### NixOS Configuration Errors
If NixOS configuration has issues:
```bash
# Validate configuration
nu scripts/validation/validate-config.nu

# Check for syntax errors
nix eval --file config/nixos/configuration.nix --raw

# Dry build
nixos-rebuild dry-build --flake .#nixos
```

### Debugging Scripts
Enable verbose logging for debugging:
```bash
# Most scripts support --verbose flag
nu scripts/maintenance/health-check.nu --verbose

# Check script syntax
nu -c "source scripts/your-script.nu"
```

## Performance Monitoring

### System Health
Regular health checks help maintain system performance:
```bash
# Run comprehensive health check
nu scripts/maintenance/health-check.nu

# Monitor system resources
nu scripts/analysis/dashboard.nu

# Check storage health
nu scripts/storage/storage-guard.nu
```

### Performance Analysis
Analyze system performance and identify bottlenecks:
```bash
# Package size analysis
nu scripts/analysis/analyze-sizes.nu

# Gaming performance
nu scripts/analysis/benchmarks/gaming-benchmark.nu

# Generate performance report
nu scripts/analysis/generate-docs.nu
```

## Security

### Configuration Security
- All configurations are version controlled
- Chezmoi provides atomic updates
- Sensitive data is managed through Chezmoi secrets

### System Security
- Regular security updates through NixOS
- Minimal attack surface with declarative configuration
- Secure boot and disk encryption support

## Advanced Usage

### Custom Scripts
Create custom scripts for your specific needs:
```bash
# Create a new script
touch scripts/custom/my-script.nu

# Make it executable
chmod +x scripts/custom/my-script.nu

# Follow the template above for consistency
```

### Platform-Specific Configuration
Platform-specific configurations are in `scripts/platforms/`:
- `scripts/platforms/linux/` - Linux-specific tools
- `scripts/platforms/macos/` - macOS-specific tools
- `scripts/platforms/windows/` - Windows-specific tools

### Testing
Run comprehensive tests to ensure everything works:
```bash
# Run all tests
nu scripts/testing/run-tests.nu

# Run specific test categories
nu scripts/testing/unit/unit-tests.nu
nu scripts/testing/integration/integration-tests.nu
```

## Contributing

### Code Style
- Use unified libraries for consistency
- Follow the script template
- Include proper error handling
- Add documentation for complex functions

### Testing
- Test scripts on multiple platforms
- Ensure error handling works correctly
- Validate that unified libraries are used properly

### Documentation
- Update this guide when adding new features
- Document any breaking changes
- Include examples for new functionality

## Support

### Getting Help
- Check the troubleshooting section above
- Review the script documentation
- Look at existing scripts for examples
- Check the unified libraries for available functions

### Reporting Issues
When reporting issues, include:
- Platform information
- Script that's failing
- Error messages
- Steps to reproduce

---

## Quick Reference

### Essential Commands
```bash
# Setup
nu scripts/setup/unified-setup.nu

# Apply configuration
make chezmoi-apply

# Validate system
nu scripts/validation/validate-config.nu

# Health check
nu scripts/maintenance/health-check.nu

# Dashboard
nu scripts/analysis/dashboard.nu
```

### File Locations
- **NixOS Config**: `config/nixos/configuration.nix`
- **User Config**: Managed by Chezmoi
- **Gaming Config**: `flakes/gaming/`
- **Scripts**: `scripts/`
- **Unified Libraries**: `scripts/lib/`

### Key Scripts
- **Setup**: `scripts/setup/unified-setup.nu`
- **Validation**: `scripts/validation/validate-config.nu`
- **Health Check**: `scripts/maintenance/health-check.nu`
- **Dashboard**: `scripts/analysis/dashboard.nu`
- **Storage Guard**: `scripts/storage/storage-guard.nu` 