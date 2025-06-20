# Safe Configuration Template Changelog

## [2024-06-20] - Updated for nix-mox latest changes

### Added

- **New Package**: `nixos-flake-update` - Added to system packages for automated NixOS flake updates
- **New Dev Shell Aliases**: Added all available nix-mox development shells:
  - `dev-default` - Default development shell with base tools
  - `dev-development` - Development tools shell
  - `dev-testing` - Testing tools shell
  - `dev-services` - Service management tools shell
  - `dev-monitoring` - Monitoring tools shell
  - `dev-gaming` - Gaming development shell (Linux x86_64 only)
  - `dev-zfs` - ZFS tools shell (Linux only)
- **New Command Alias**: `nixos-update` - Quick access to nixos-flake-update command

### Updated

- **README.md**: Updated documentation to include all new packages and dev shells
- **setup.sh**: Updated setup script to include new package and dev shell aliases
- **configuration.nix**: Added nixos-flake-update to system packages
- **home.nix**: Added all new dev shell aliases and nixos-update command

### Technical Changes

- Test framework moved from `tests/` to `scripts/tests/` (internal change, doesn't affect safe config)
- All tests continue to pass ✅
- Display safety features remain intact
- nix-mox integration working correctly

### Compatibility

- **Backward Compatible**: All existing configurations will continue to work
- **New Features**: New packages and dev shells are available but optional
- **Display Safety**: No changes to display configuration that could cause CLI lock

### Usage

After updating, users can access:

```bash
# New system package
nixos-flake-update

# New dev shells
dev-default
dev-development
dev-testing
dev-services
dev-monitoring
dev-gaming
dev-zfs

# Quick command alias
nixos-update
```
