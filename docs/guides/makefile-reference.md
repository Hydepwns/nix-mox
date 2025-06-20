# Makefile Reference Guide

## Overview

The nix-mox Makefile provides convenient shortcuts for common development tasks. This guide documents all available targets with detailed explanations and usage examples.

## Quick Reference

```bash
make help          # Show all available targets
make test          # Run all tests
make dev           # Enter development shell
make format        # Format Nix files
make check         # Run flake checks
make build-all     # Build all packages
make clean         # Clean test artifacts
```

## Target Categories

### Testing Targets

#### `make test`

Run all tests with coverage reporting.

```bash
make test
```

**What it does:**

- Creates test directory if needed
- Runs the complete test suite via `scripts/tests/run-tests.nu`
- Generates coverage reports in `coverage-tmp/nix-mox-tests/`

**Use when:**

- Before committing changes
- During development to verify functionality
- After making significant changes

#### `make unit`

Run unit tests only.

```bash
make unit
```

**What it does:**

- Runs only unit tests from `scripts/tests/unit/`
- Faster execution than full test suite
- Good for quick feedback during development

**Use when:**

- During active development
- Need quick feedback on changes
- Testing individual components

#### `make integration`

Run integration tests only.

```bash
make integration
```

**What it does:**

- Runs only integration tests from `scripts/tests/integration/`
- Tests end-to-end functionality
- Platform-specific validation

**Use when:**

- Testing complete workflows
- Validating cross-component integration
- Platform-specific testing

#### `make clean`

Clean up test artifacts.

```bash
make clean
```

**What it does:**

- Removes `coverage-tmp/` directory
- Removes coverage report files (`coverage.json`, `coverage.yaml`, `coverage.toml`)

**Use when:**

- Freeing up disk space
- Resolving test issues
- Before running fresh tests

### Development Targets

#### `make dev`

Enter the default development shell.

```bash
make dev
```

**What it does:**

- Enters the default development environment
- Provides essential development tools
- Sets up environment variables

**Use when:**

- Starting a development session
- Need basic development tools
- General development work

#### `make format`

Format Nix files using nixpkgs-fmt.

```bash
make format
```

**What it does:**

- Formats all `.nix` files in the project
- Ensures consistent code style
- Uses `nix fmt` command

**Use when:**

- Before committing code
- After making changes to Nix files
- Maintaining code style consistency

#### `make check`

Run nix flake check.

```bash
make check
```

**What it does:**

- Validates the flake configuration
- Runs all flake checks
- Verifies package builds

**Use when:**

- Before committing changes
- Validating flake configuration
- Ensuring package compatibility

### Build Targets

#### `make build`

Build the default package.

```bash
make build
```

**What it does:**

- Builds the default package (proxmox-update)
- Uses `nix build .#default`

**Use when:**

- Testing the default package
- Quick build verification
- Development testing

#### `make build-all`

Build all available packages.

```bash
make build-all
```

**What it does:**

- Builds all packages: `proxmox-update`, `vzdump-backup`, `zfs-snapshot`, `nixos-flake-update`
- Shows progress for each package
- Exits on first failure

**Use when:**

- Before releasing
- Testing all packages
- Validating cross-package compatibility

### CI/CD Targets

#### `make ci-test`

Run quick CI test locally.

```bash
make ci-test
```

**What it does:**

- Runs `./scripts/ci-test.sh`
- Quick validation of CI workflow
- Tests essential components

**Use when:**

- During development
- Quick CI validation
- Before pushing changes

#### `make ci-local`

Run comprehensive CI test locally.

```bash
make ci-local
```

**What it does:**

- Runs `./scripts/test-ci-local.sh`
- Simulates full GitHub Actions workflow
- Comprehensive testing

**Use when:**

- Before pushing to main branch
- Full CI validation
- Release preparation

### Maintenance Targets

#### `make update`

Update flake inputs.

```bash
make update
```

**What it does:**

- Updates all flake inputs to latest versions
- Uses `nix flake update`

**Use when:**

- Keeping dependencies up to date
- Before major releases
- Resolving dependency issues

#### `make lock`

Update flake.lock.

```bash
make lock
```

**What it does:**

- Updates the flake.lock file
- Uses `nix flake lock`

**Use when:**

- After updating flake inputs
- Resolving lock file issues
- Ensuring reproducible builds

#### `make clean-all`

Clean all artifacts and temporary files.

```bash
make clean-all
```

**What it does:**

- Runs `make clean`
- Removes `tmp/` directory
- Removes `result/` directory
- Runs `nix store gc`

**Use when:**

- Freeing up significant disk space
- Resolving persistent issues
- Fresh start after problems

### Information Targets

#### `make packages`

Show available packages.

```bash
make packages
```

**What it does:**

- Lists all available packages
- Shows package descriptions

**Use when:**

- Discovering available packages
- Understanding project scope
- Documentation reference

#### `make shells`

Show available development shells.

```bash
make shells
```

**What it does:**

- Lists all available development shells
- Shows platform-specific shells

**Use when:**

- Discovering available shells
- Understanding platform support
- Choosing development environment

### Development Shell Targets

#### `make test-shell`

Enter testing development shell.

```bash
make test-shell
```

**What it does:**

- Enters testing environment
- Provides test-specific tools

#### `make services-shell`

Enter services development shell.

```bash
make services-shell
```

**What it does:**

- Enters service development environment
- Provides service development tools

#### `make monitoring-shell`

Enter monitoring development shell.

```bash
make monitoring-shell
```

**What it does:**

- Enters monitoring environment
- Provides monitoring and observability tools

#### `make storage-shell`

Enter storage development shell.

```bash
make storage-shell
```

**What it does:**

- Enters storage development environment
- Provides ZFS and storage tools

#### `make gaming-shell`

Enter gaming development shell (Linux x86_64 only).

```bash
make gaming-shell
```

**What it does:**

- Enters gaming development environment
- Provides gaming tools (Steam, Wine, Lutris, etc.)

#### `make macos-shell`

Enter macOS development shell (macOS only).

```bash
make macos-shell
```

**What it does:**

- Enters macOS development environment
- Provides macOS-specific tools and frameworks

## Common Workflows

### Daily Development

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

### Pre-commit Checklist

```bash
make test          # Ensure tests pass
make format        # Format code
make check         # Run flake checks
make clean         # Clean artifacts
```

### Pre-push Validation

```bash
make ci-local      # Run comprehensive CI test
```

### Package Development

```bash
make build-all     # Build all packages
make test          # Run tests
make check         # Validate flake
```

### Troubleshooting

```bash
make clean-all     # Clean everything
make test          # Run tests again
```

## Variables

The Makefile uses several variables for maintainability:

- `TEST_DIR` - Test directory path
- `TEST_TEMP_DIR` - Test temporary directory
- `NUSHELL` - Nushell command
- `NIX` - Nix command
- `PACKAGES` - List of available packages

## Best Practices

1. **Use `make help`** to discover available targets
2. **Run `make test`** frequently during development
3. **Use `make format`** before committing
4. **Use `make ci-local`** before pushing to main
5. **Use `make clean-all`** when troubleshooting
6. **Use `make build-all`** before releases

## Troubleshooting

### Common Issues

1. **Permission Errors**

   ```bash
   make clean
   make test
   ```

2. **Build Failures**

   ```bash
   make build-all
   make clean-all
   ```

3. **Flake Issues**

   ```bash
   make update
   make lock
   ```

### Debug Mode

```bash
$env.DEBUG = true
make test
```

## Related Documentation

- [Development Workflow Guide](./development-workflow.md)
- [Testing Guide](./testing.md)
- [CI/CD Guide](./ci-cd.md)
