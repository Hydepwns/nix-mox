# nix-mox Scripts

This directory contains all platform-specific and automation scripts for the nix-mox toolkit.

## Main Entrypoint

The primary entrypoint for automation is the bash wrapper script:

```bash
./nix-mox
```

### Usage

Run the script with:

```bash
./nix-mox --script install --dry-run
```

> **Note:** The wrapper script ensures robust argument passing for all Nushell versions and platforms. You no longer need to worry about double-dash (`--`) or Nushell quirks.

### Options

- `-h, --help`           Show help message
- `--dry-run`           Show what would be done without making changes
- `--debug`             Enable debug output
- `--platform <os>`     Specify platform (auto, linux, darwin, nixos)
- `--script <name>`     Run specific script (install, update, zfs-snapshot)
- `--log <file>`        Log output to file

### Platform & OS Info

- When running a script, nix-mox prints detailed OS info (distro, version, kernel) for Linux/NixOS, macOS, or Windows.
- NixOS is fully supported and detected as a Linux platform.

### Error Handling & Logging

- All error handling and logging is robust and platform-aware.
- Errors are clearly reported, and logs can be written to a file with `--log <file>`.

## Key Scripts

### Interactive Setup Wizard

The `setup-wizard.nu` script provides an interactive, user-friendly setup experience:

```bash
./scripts/setup-wizard.nu
```

**Features:**

- Platform detection and validation
- Use case selection (Desktop, Server, Development, Gaming, etc.)
- Feature selection with descriptions
- Basic system configuration (hostname, timezone, username)
- Hardware configuration guidance
- Automatic file generation
- Color-coded interface with clear instructions

### Health Check System

The `health-check.nu` script validates system health and configuration integrity:

```bash
./scripts/health-check.nu
./scripts/health-check.nu --check nix-store
./scripts/health-check.nu --check services
```

**Features:**

- nix-mox environment validation
- Configuration file syntax checking
- Flake syntax and dependency validation
- NixOS configuration validation
- System services status monitoring
- Disk and memory usage analysis
- Network connectivity testing
- Nix store integrity verification
- Security settings validation
- Color-coded reports with recommendations

### Security Module Validation

The security module provides comprehensive enterprise-grade security features:

```bash
# Validate security module configuration
make security-check

# Or manually check security module
nix eval --impure --expr 'with import <nixpkgs> {}; callPackage ./modules/security/index.nix {}'
```

**Available Security Features:**

- **Fail2ban**: Intrusion prevention with configurable jails and ban policies
- **UFW Firewall**: Uncomplicated firewall with rule management and port control  
- **SSL/TLS Security**: Certificate management, modern ciphers, and security headers
- **AppArmor**: Mandatory access control for application security
- **System Auditing**: Comprehensive audit rules and log management
- **SELinux Support**: Advanced mandatory access control (optional)
- **Kernel Security**: Lockdown modes, YAMA, seccomp, and stack protection
- **Network Hardening**: IPv6 privacy, TCP hardening, ICMP rate limiting
- **File System Security**: Read-only mounts, noexec, nosuid options
- **User Security**: Password policies, account lockout, and complexity requirements

**Usage:**

```bash
# Enable all security features
imports = [ modules.security.all ];

# Or enable individual components
imports = [
  modules.security.fail2ban
  modules.security.ufw
  modules.security.ssl
  modules.security.apparmor
];
```

## Directory Structure

- `nix-mox`             — Main automation entrypoint (bash wrapper)
- `nix-mox.nu`          — Nushell automation logic
- `setup-wizard.nu`     — Interactive configuration wizard
- `health-check.nu`     — System health diagnostics
- `common/`             — Shared script utilities
  - `nix-mox`           — Common nix-mox utilities
  - `nix-mox-uninstall.sh` — Uninstall script
  - `install-nix.sh`    — Nix installation script
- `linux/`              — Linux-specific scripts (install, update, zfs, etc.)
- `windows/`            — Windows-specific scripts
- `lib/`                — Script libraries and helpers
  - `argparse.nu`       — Argument parsing utilities
  - `common.nu`         — Common utilities
  - `exec.nu`           — Execution helpers
  - `logging.nu`        — Logging utilities
  - `platform.nu`       — Platform detection

## Script Development

- Use the utilities in `lib/common.nu` for logging, error handling, and platform detection.
- Follow the argument parsing and error handling patterns in `nix-mox.nu` for new scripts.
- See the [Script Development Guide](../../docs/guides/scripting.md) for best practices and advanced usage.

## Troubleshooting

- If you see `[ERROR] No script specified`, check your invocation method and ensure you are using the wrapper script.
- For Nushell versions that do not support argument passing, the wrapper script will handle it for you.
- Use `--debug` flag for detailed error information and troubleshooting.

## Example Invocations

```bash
# Install (dry run)
./nix-mox --script install --dry-run

# Update packages
./nix-mox --script update

# ZFS snapshot (Linux only)
./nix-mox --script zfs-snapshot

# Run setup wizard
./scripts/setup-wizard.nu

# Run health check
./scripts/health-check.nu

# Or use Makefile targets
make setup-wizard
make health-check
```

## Benefits

### For New Users

- **Simplified Onboarding:** Interactive wizard guides through setup
- **Reduced Errors:** Automated configuration generation
- **Better Understanding:** Clear explanations of each option
- **Faster Setup:** Streamlined process with sensible defaults

### For Existing Users

- **System Validation:** Health check ensures configuration integrity
- **Easy Troubleshooting:** Comprehensive diagnostics and recommendations
- **Better Organization:** Template-based hardware configuration
- **Enhanced Modules:** Complete feature sets for development, security, and hardware

### For Developers

- **Consistent Interface:** Makefile targets for common operations
- **Better Testing:** Health check validates system state
- **Modular Design:** Complete, well-organized modules
- **Clear Documentation:** Comprehensive guides and examples
