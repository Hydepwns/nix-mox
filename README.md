# nix-mox

> Enterprise-grade NixOS gaming workstation with safety automation

[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI%20(Simplified)/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml) [![Platforms](https://img.shields.io/badge/platforms-linux%20%7C%20macos%20%7C%20windows-blue.svg)](https://github.com/Hydepwns/nix-mox/actions) [![Tests](https://img.shields.io/badge/tests-100%25-brightgreen.svg)](https://github.com/Hydepwns/nix-mox/actions)

## Quick Start

**Prerequisites**: NixOS, user `hydepwns`, shell access

⚠️ **KDE Plasma 6 + NVIDIA Issues**: Lock screen loops, black screens  
**Emergency**: TTY (Ctrl+Alt+F2) → `cd nix-mox` → `make emergency-display-recovery`  
**Auto-fixes**: X11 forced, NVIDIA beta drivers, SDDM compatibility

### Installation
```bash
git clone https://github.com/hydepwns/nix-mox.git && cd nix-mox
./bootstrap-check.sh
nu scripts/setup/component-browser.nu
make chezmoi-apply storage-guard safe-rebuild
```

🛡️ **Safety Rules**: Never use `nixos-rebuild` directly, always run `storage-guard` before reboot

## Essential Commands
```bash
make help dev test safe-rebuild    # Core workflow
make storage-guard display-fix     # Safety operations  
make chezmoi-apply dashboard       # Config & monitoring
```

## Features

| Category | Features |
|----------|----------|
| **Gaming** | Steam, Lutris, GameMode, Hardware auto-detect |
| **Security** | Encrypted secrets, auto-rollback, automated backup |
| **Performance** | CPU performance, Zram, BBR network, SSD optimization |
| **Setup** | Interactive wizard, smart auto-detection |
| **DevEx** | Modular architecture, subflakes, comprehensive testing |

## Architecture

**Libraries**: `logging.nu`, `validators.nu`, `command-wrapper.nu`, `platform.nu`, `secure-command.nu`  
**Chezmoi**: Cross-platform dotfiles with templates and Git versioning

**Configuration**:
- **NixOS**: `config/nixos/configuration.nix` - System packages, hardware, security
- **User**: Chezmoi templates - Shell, Git, editors, packages, environment  
- **Gaming**: `flakes/gaming/` - GPU drivers, gaming tools, optimizations

## Documentation

- 📚 [USER_GUIDE.md](USER_GUIDE.md) - Detailed usage guide
- 🔧 [CLAUDE.md](CLAUDE.md) - Development commands  
- 🛡️ [docs/SECURITY.md](docs/SECURITY.md) - Security features
- 📝 [docs/SCRIPTS.md](docs/SCRIPTS.md) - Script reference
- 🔍 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem resolution

## Development

### Pre-commit Hooks
Comprehensive validation: snake_case naming, syntax validation, secret detection, import validation, large file detection, conventional commits.

```bash
nix develop              # Enter dev environment
nix run .#fmt           # Format code
nix run .#validate      # Validate configuration  
nix run .#update        # Update flake inputs
nix run .#storage-guard # Validate storage before reboot
```

### Available Operations
```bash
# Backup & Storage
nu scripts/storage/backup.nu           # Manual backup
nu scripts/storage/health-checks.nu    # Storage health validation

# Security & Secrets  
make security-check                    # Security validation
tail -f logs/security.log              # Review security audit logs

# System Recovery
make emergency-display-recovery        # Display issues recovery
make safe-rebuild --backup             # Safe system rebuild with backup
```

## Quick Reference

### File Locations
- **NixOS Config**: `config/nixos/configuration.nix`
- **User Config**: Managed by Chezmoi
- **Gaming Config**: `flakes/gaming/`
- **Scripts**: `scripts/` with unified libraries in `scripts/lib/`

### Key Operations
```bash
# Setup
nu scripts/setup/component-browser.nu

# Validation & Health  
make validate-config health-check

# System Changes (NEVER use nixos-rebuild directly)
make storage-guard safe-rebuild

# Monitoring
make dashboard

# Emergency (from TTY)
make emergency-display-recovery
```

For comprehensive guides, see the documentation links above.