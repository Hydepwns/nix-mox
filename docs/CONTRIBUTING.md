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
   nix develop .#services    # For service development
   nix develop .#monitoring  # For monitoring tools
   nix develop .#zfs         # For ZFS-related development (Linux only)
   ```

3. Quick development commands:

   ```bash
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

- Use `nixpkgs-fmt` for Nix files
- Follow existing code style
- Add comments for complex logic
- Keep functions focused
- Ensure Linux-specific packages are properly guarded

## Testing

Before submitting changes, ensure all tests pass:

```bash
# Run all tests
make test

# Run specific test types
make unit
make integration

# Run via Nix flake (recommended for CI)
nix flake check

# Build all packages locally
nix build .#proxmox-update .#vzdump-backup .#zfs-snapshot .#nixos-flake-update

# Clean up test artifacts
make clean
```

### Continuous Integration

The project uses GitHub Actions for CI/CD with the following workflow:

1. **Package Building**: Builds all packages on multiple platforms (`x86_64-linux`, `aarch64-linux`)
2. **Testing**: Runs the integrated test suite using `nix flake check`
3. **Multi-version Testing**: Tests against multiple Nix versions (2.19.2, 2.20.1)

All tests must pass before merging pull requests. See [Testing Guide](./guides/testing.md) for detailed information.

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
