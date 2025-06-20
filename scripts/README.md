# nix-mox Scripts

This directory contains all platform-specific and automation scripts for the nix-mox toolkit.

## Main Entrypoint

The primary entrypoint for automation is now the bash wrapper script:

```
modules/scripts/nix-mox
```

### Usage

Run the script with:

```bash
./modules/scripts/nix-mox --script install --dry-run
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

## Directory Structure

- `nix-mox`             — Main automation entrypoint (bash wrapper)
- `nix-mox.nu`          — Nushell automation logic
- `common.nu`           — Shared utilities and logging
- `linux/`              — Linux-specific scripts (install, update, zfs, etc.)
- `windows/`            — Windows-specific scripts
- `testing/`            — Test infrastructure and helpers
- `lib/`                — Script libraries and helpers

## Script Development

- Use the utilities in `common.nu` for logging, error handling, and platform detection.
- Follow the argument parsing and error handling patterns in `nix-mox.nu` for new scripts.
- See the [Script Development Guide](../../docs/guides/scripting.md) for best practices and advanced usage.

## Troubleshooting

- If you see `[ERROR] No script specified`, check your invocation method and ensure you are using the wrapper script.
- For Nushell versions that do not support argument passing, the wrapper script will handle it for you.

## Example Invocations

```bash
# Install (dry run)
./modules/scripts/nix-mox --script install --dry-run

# Update packages
./modules/scripts/nix-mox --script update

# ZFS snapshot (Linux only)
./modules/scripts/nix-mox --script zfs-snapshot
``` 