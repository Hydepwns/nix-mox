# Script Reference

> **Quick Access**: Use `make help` for interactive command list

## Core Operations

| Command | Purpose | Context |
|---------|---------|---------|
| `make help` | Show all available commands | Always start here |
| `make dev` | Enter development shell | Development |
| `make safe-rebuild` | System rebuild with validation | System changes |
| `make storage-guard` | Pre-reboot storage validation | **MANDATORY before reboot** |
| `make validate-config` | Validate NixOS configuration | Before system changes |

## Categories

### 🛡️ Safety & Validation
- **storage-guard** - MANDATORY before reboot
- **safe-rebuild** - NEVER use `nixos-rebuild` directly
- **validate-config** - NixOS configuration validation
- **pre-rebuild-safety-check** - Comprehensive pre-rebuild validation
- **post-rebuild-validation** - Post-rebuild system validation

### 📊 Analysis & Monitoring  
- **dashboard** - Interactive system overview
- **dashboard-system** - Detailed system information
- **dashboard-performance** - Performance metrics
- **analyze-sizes** - Package and build size analysis
- **health-check** - System health validation

### 🎮 Gaming
- **gaming-setup** - Gaming environment configuration
- **setup-proton-ge** - Proton GE installation
- **setup-steam-eac** - Steam EAC compatibility
- **gaming-benchmark** - Performance testing

### 🔧 Development
- **setup** - Interactive system setup
- **chezmoi-*** - User configuration management
- **test**, **coverage** - Testing and coverage
- **fmt** - Code formatting

### 🔒 Security
- **security-check** - Security validation
- **validate-script-security** - Script security analysis
- **privilege-manager** - Privilege control system

### 🖥️ Display (KDE + NVIDIA)
- **display-fix** - Auto-fix display issues  
- **display-troubleshoot** - Diagnose KDE+NVIDIA problems
- **emergency-display-recovery** - TTY recovery for lock screen issues

### 📦 Package Management
- **update** - Update flake inputs
- **build**, **build-all** - Build packages
- **cache-optimize** - Optimize build cache

## Platform-Specific

### Linux
- **nixos-flake-update** - NixOS system update
- **zfs-snapshot** - ZFS snapshot management
- **proxmox-update** - Proxmox container updates
- **install**, **uninstall** - System installation

### macOS  
- **homebrew-setup** - Homebrew installation
- **macos-maintenance** - System maintenance
- **security-audit** - macOS security check

### Windows
- **install-steam-rust** - Gaming environment
- **powershell** scripts - Windows-specific operations

## Usage Patterns

### System Changes Workflow
```bash
make validate-config     # Validate configuration
make storage-guard       # MANDATORY storage check  
make safe-rebuild        # Safe system rebuild
```

### Development Workflow  
```bash
make dev                 # Enter development shell
make fmt                 # Format code
make test                # Run tests
make ci-local           # Full CI pipeline
```

### Gaming Setup
```bash
make gaming-shell        # Gaming development environment
make gaming-setup        # Configure gaming
make gaming-test         # Validate setup
```

### Emergency Recovery
```bash
# From TTY (Ctrl+Alt+F2)
make emergency-display-recovery
make display-fix
make display-troubleshoot
```

## Script Locations

| Path | Purpose |
|------|---------|
| `scripts/` | Core consolidated scripts |
| `scripts/lib/` | Shared libraries |
| `scripts/platforms/` | Platform-specific operations |
| `scripts/testing/` | Test suites |
| `scripts/maintenance/` | System maintenance |
| `scripts/storage/` | Storage safety operations |
| `scripts/validation/` | Validation systems |
| `scripts/analysis/` | System analysis tools |

## Safety Rules

### ❌ NEVER
- Use `nixos-rebuild` directly
- Reboot without `make storage-guard`
- Skip validation before system changes
- Use `^sh -c` for command execution
- Bypass security validation

### ✅ ALWAYS  
- Use `make safe-rebuild` for system changes
- Run `make storage-guard` before reboots
- Work in `nix develop` shell
- Use secure command wrappers
- Review `logs/security.log` regularly

## Script Discovery

```bash
# Find scripts by pattern
find scripts/ -name "*pattern*.nu"

# List by category  
ls scripts/platforms/linux/  # Linux-specific
ls scripts/testing/unit/     # Unit tests
ls scripts/analysis/         # Analysis tools

# Search script content
grep -r "function_name" scripts/
```

For detailed command documentation, see [CLAUDE.md](CLAUDE.md).