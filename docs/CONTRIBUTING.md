# Contributing to nix-mox

## Development Setup

1. Install Nix:

   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Enter development environment:

   ```bash
   # Default development environment with Cursor IDE and Kitty terminal
   nix develop

   # Or use specific development shells
   nix develop .#development  # For general development
   nix develop .#testing     # For testing
   nix develop .#services    # For service development (Linux)
   nix develop .#monitoring  # For monitoring tools (Linux)
   nix develop .#gaming      # For gaming tools (Linux)
   nix develop .#macos       # For macOS tools (macOS)
   ```

3. Quick development commands:

   ```bash
   # Format all code
   nix run .#fmt

   # Run tests
   nix run .#test

   # Update flake inputs
   nix run .#update

   # Open Cursor IDE
   cursor .

   # Open new terminal
   kitty
   open-terminal

   # Proxmox management (Linux only)
   virt-manager
   virsh list --all
   nix run .#proxmox-update
   ```

## Package Structure

The project provides the following packages (Linux only):

- **proxmox-update**: Update and upgrade Proxmox host packages safely
- **vzdump-backup**: Backup Proxmox VMs and containers using vzdump
- **zfs-snapshot**: Create and manage ZFS snapshots with automatic pruning
- **nixos-flake-update**: Update NixOS flake inputs and system

## Guidelines

- Use `nix run .#fmt` to format all code before committing
- Follow existing code style and patterns
- Add comments for complex logic
- Keep functions focused and small
- Ensure Linux-specific packages are properly guarded
- Test changes on target platforms
- Update documentation when adding features

## Testing

Before submitting changes, ensure all tests pass:

```bash
# Run all tests
nix run .#test

# Run specific test types
nix build .#checks.x86_64-linux.unit
nix build .#checks.x86_64-linux.integration

# Run via Nix flake (recommended for CI)
nix flake check

# Build all packages locally
nix build .#proxmox-update .#vzdump-backup .#zfs-snapshot .#nixos-flake-update

# Format code before committing
nix run .#fmt

# Clean up test artifacts
make clean
```

### Coverage Testing

The project includes comprehensive coverage reporting:

```bash
# Generate coverage reports
make coverage          # LCOV format (recommended for Codecov)
make coverage-grcov    # Rust-based coverage (requires Rust)
make coverage-local    # Local development coverage

# Run tests with coverage
make test && make coverage

# Check coverage locally
cat coverage-tmp/coverage-summary.json
```

### Coverage Options

- **LCOV Coverage** (Recommended): Standard format compatible with Codecov
- **grcov Coverage**: Advanced Rust-based line-by-line coverage
- **tarpaulin Coverage**: Simplified Rust coverage tool
- **Custom Coverage**: Test result tracking and analysis

See [Coverage Documentation](./COVERAGE.md) for detailed information.

### Continuous Integration

The project uses GitHub Actions for CI/CD with the following workflow:

1. **Package Building**: Builds all packages on multiple platforms (`x86_64-linux`, `aarch64-linux`)
2. **Testing**: Runs the integrated test suite using `nix flake check`
3. **Coverage**: Generates and uploads coverage reports to Codecov
4. **Multi-version Testing**: Tests against multiple Nix versions (2.19.2, 2.20.1)
5. **Multi-platform**: Tests run on Linux and macOS

All tests must pass and coverage reports must be generated before merging pull requests. See [Testing Guide](./guides/testing.md) for detailed information.

## Pull Request Process

1. Fork and create feature branch
2. Make changes
3. Run tests locally
4. Ensure CI passes
5. Submit PR

## Commit Messages

Use conventional commits:

- feat: new feature
- fix: bug fix
- docs: documentation
- style: formatting
- refactor: code changes
- test: tests
- chore: maintenance

## Questions?

Open an issue for any questions.
