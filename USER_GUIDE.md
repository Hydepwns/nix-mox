# User Guide

> **Quick Start**: See [README.md](README.md) for installation  
> **Development**: See [CLAUDE.md](CLAUDE.md) for commands

## Configuration Management

### NixOS System Config
**File**: `config/nixos/configuration.nix`  
**Contains**: System packages, services, hardware, security, networking

### User Config (Chezmoi) 
**Templates**: Shell, Git, editors, packages, environment variables  
**Commands**: `make chezmoi-apply chezmoi-diff chezmoi-sync chezmoi-edit`

### Gaming Config
**Path**: `flakes/gaming/`  
**Includes**: GPU drivers, gaming tools, performance optimizations, controllers

## Development Workflow

### Script Template
```nushell
#!/usr/bin/env nu
use ../lib/{logging,validators,platform}.nu *

def main [] {
    banner "Script Name"
    let platform = (get_platform)
    # Logic here
    success "Completed"
}
```

### Error Handling
```nushell
# Safe execution (from secure-command.nu)
let result = (secure_execute "command" ["args"])
if not $result.success { error $result.stderr --context "script"; exit 1 }

# Requirements validation
require_command "nix"; require_file "config/file"
validate_requirements ["nix" "git" "nu"]
```

### Validation Patterns
```nushell
# Platform checks
if not (is_platform "linux") { error "Linux only"; exit 1 }

# File validation  
if not (validate_config_file "file.nix") { exit 1 }

# Command availability
validate_requirements ["nix" "git" "nu"]
```

## Operations Guide

### System Changes
```bash
make validate-config storage-guard safe-rebuild  # Never use nixos-rebuild directly
```

### Monitoring
```bash
make dashboard health-check     # System status
make analyze-sizes quality      # Analysis  
```

### Troubleshooting
```bash
make display-fix                # KDE+NVIDIA issues
make emergency-display-recovery # Lock screen problems
make storage-health             # Storage validation
journalctl -xe                  # System logs
```

### Gaming
```bash
make gaming-setup gaming-test   # Gaming configuration
make gaming-shell              # Gaming development environment
```

### Security
```bash
make security-check            # Security validation
tail -f logs/security.log      # Security audit log
```

## Advanced Usage

### Custom Configurations
1. **System packages**: Edit `config/nixos/configuration.nix`
2. **User dotfiles**: Edit Chezmoi templates 
3. **Gaming**: Modify `flakes/gaming/`
4. **Validation**: Always run `make validate-config` after changes

### Platform-Specific Operations
- **Linux**: Full NixOS system management
- **macOS/Windows**: User configuration only via Chezmoi

### Environment Variables
- `NIX_MOX_ENV`: Environment type (dev/prod/test)
- `CHEZMOI_SOURCE_DIR`: Chezmoi source directory
- `GAMING_MODE`: Enable gaming optimizations

## Best Practices

### Safety Rules
- Use `make safe-rebuild` instead of `nixos-rebuild`
- Run `make storage-guard` before reboots
- Validate configurations before applying: `make validate-config`
- Keep backups: `make safe-rebuild --backup`

### Development
- Work in `nix develop` shell
- Format code: `make fmt` before commits
- Test changes: `make test ci-local` 
- Use security wrappers: `secure_execute()` vs `^sh -c`

### Monitoring
- Check system health: `make health-check` weekly
- Review security logs: `logs/security.log` monthly
- Monitor performance: `make dashboard-performance`
- Clean up: `make clean-all` regularly