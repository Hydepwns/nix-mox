# Contributing to nix-mox

## Development Setup

1. Install Nix:

   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Enter development environment:

   ```bash
   # Default development environment
   nix develop

   # Or use specific development shells
   nix develop .#development  # For general development
   nix develop .#testing     # For testing
   nix develop .#services    # For service development
   nix develop .#monitoring  # For monitoring tools
   nix develop .#zfs         # For ZFS-related development (Linux only)
   ```

## Package Structure

The project provides the following packages (Linux only):

- **proxmox-update**: Update and upgrade Proxmox host packages safely
- **vzdump-backup**: Backup Proxmox VMs and containers using vzdump
- **zfs-snapshot**: Create and manage ZFS snapshots with automatic pruning

## Guidelines

- Use `nixpkgs-fmt` for Nix files
- Follow existing code style
- Add comments for complex logic
- Keep functions focused
- Ensure Linux-specific packages are properly guarded

## Testing

```bash
nu scripts/core/run-tests.nu
```

## Pull Request Process

1. Fork and create feature branch
2. Make changes
3. Run tests
4. Submit PR

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
