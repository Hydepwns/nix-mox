# Development Workflow Guide

## Overview

This guide covers the development workflow for nix-mox, including the available Make targets, best practices, and common development tasks.

## Quick Reference

```bash
# Essential commands
make help          # Show all available targets
make dev           # Enter development shell
make test          # Run all tests
make format        # Format code
make check         # Run flake checks
make build-all     # Build all packages
make clean         # Clean test artifacts
```

## Available Make Targets

### Testing

- **`make test`** - Run all tests with coverage
- **`make unit`** - Run unit tests only
- **`make integration`** - Run integration tests only
- **`make clean`** - Clean test artifacts

### Development

- **`make dev`** - Enter development shell
- **`make format`** - Format Nix files
- **`make check`** - Run nix flake check
- **`make build`** - Build default package
- **`make build-all`** - Build all packages

### CI/CD

- **`make ci-test`** - Quick CI test locally
- **`make ci-local`** - Comprehensive CI test locally

### Maintenance

- **`make update`** - Update flake inputs
- **`make lock`** - Update flake.lock
- **`make clean-all`** - Clean all artifacts

### Information

- **`make packages`** - Show available packages
- **`make shells`** - Show available shells

## Development Workflow

### 1. Initial Setup

```bash
# Clone the repository
git clone https://github.com/hydepwns/nix-mox.git
cd nix-mox

# Enter development environment
make dev

# Verify setup
make test
```

### 2. Daily Development

```bash
# Start development session
make dev

# Run tests to ensure everything works
make test

# Make your changes...

# Run tests again
make test

# Format code
make format

# Run full validation
make check
```

### 3. Before Committing

```bash
# Run the pre-commit checklist
make test          # Ensure tests pass
make format        # Format code
make check         # Run flake checks
make clean         # Clean artifacts

# Optional: Build all packages
make build-all

# Commit changes
git add .
git commit -m "feat: your feature description"
```

### 4. Before Pushing

```bash
# Run comprehensive CI test locally
make ci-local

# If everything passes, push
git push origin your-branch
```

## Development Shells

nix-mox provides several specialized development shells:

### Available Shells

```bash
make dev              # Default development shell
make test-shell       # Testing environment
make services-shell   # Service development
make monitoring-shell # Monitoring tools
make zfs-shell         # Storage tools
```

### Platform-Specific Shells

```bash
# Linux only
make gaming-shell     # Gaming development (x86_64 only)
make zfs-shell         # ZFS tools

# macOS only
make macos-shell      # macOS development
```

### Shell Features

Each shell includes:

- Platform-specific tools
- Development utilities
- Documentation and examples
- Helpful shell hooks

## Package Development

### Building Packages

```bash
# Build default package
make build

# Build all packages
make build-all

# Build specific package
nix build .#proxmox-update
nix build .#vzdump-backup
nix build .#zfs-snapshot
nix build .#nixos-flake-update
```

### Available Packages

```bash
make packages
```

Shows:

- `proxmox-update` - Update Proxmox host packages
- `vzdump-backup` - Backup Proxmox VMs and containers
- `zfs-snapshot` - ZFS snapshot management
- `nixos-flake-update` - NixOS flake updates

## Testing Strategy

### Test Types

1. **Unit Tests** (`make unit`)
   - Fast, isolated component testing
   - Mock external dependencies
   - Located in `scripts/tests/unit/`

2. **Integration Tests** (`make integration`)
   - End-to-end functionality testing
   - Platform-specific validation
   - Located in `scripts/tests/integration/`

3. **Flake Checks** (`make check`)
   - Nix flake validation
   - Package building verification
   - Cross-platform compatibility

### Testing Workflow

```bash
# During development
make unit           # Quick feedback

# Before committing
make test           # Full test suite

# Before pushing
make ci-local       # Comprehensive CI simulation
```

## Code Quality

### Formatting

```bash
# Format Nix files
make format

# Or manually
nix fmt
```

### Validation

```bash
# Run flake checks
make check

# Or manually
nix flake check
```

## Troubleshooting

### Common Issues

1. **Test Failures**

   ```bash
   make clean        # Clean test artifacts
   make test         # Run tests again
   ```

2. **Build Failures**

   ```bash
   make build-all    # Identify problematic packages
   make clean-all    # Clean everything
   ```

3. **Flake Issues**

   ```bash
   make update       # Update flake inputs
   make lock         # Update flake.lock
   ```

### Debug Mode

```bash
# Enable debug output
$env.DEBUG = true
make test
```

### Clean Start

```bash
# Clean everything and start fresh
make clean-all
make test
```

## Best Practices

### 1. Development Habits

- Run tests frequently during development
- Use `make unit` for quick feedback
- Use `make test` before committing
- Use `make ci-local` before pushing

### 2. Code Quality

- Always format code with `make format`
- Run flake checks with `make check`
- Keep test artifacts clean with `make clean`

### 3. Package Development

- Test package builds with `make build-all`
- Verify cross-platform compatibility
- Update documentation when adding new packages

### 4. CI/CD

- Test CI workflow locally before pushing
- Use `make ci-test` for quick validation
- Use `make ci-local` for comprehensive testing

## Integration with IDEs

### VS Code

Add to your workspace settings:

```json
{
  "nix.enable": true,
  "nix.serverPath": "nix",
  "files.associations": {
    "*.nix": "nix"
  }
}
```

### Shell Integration

Add to your shell profile:

```bash
# Quick access to nix-mox development
alias nixmox='cd /path/to/nix-mox && make dev'
alias nixmox-test='cd /path/to/nix-mox && make test'
```

## Related Documentation

- [Testing Guide](./testing.md) - Detailed testing information
- [CI/CD Guide](./ci-cd.md) - Continuous integration setup
- [Script Development Guide](./scripting.md) - Script development practices
- [Architecture Documentation](../architecture/ARCHITECTURE.md) - System design
