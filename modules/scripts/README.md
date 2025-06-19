# nix-mox Scripts

This directory contains all platform-specific and automation scripts for the nix-mox toolkit.

## Main Entrypoint

The primary entrypoint for automation is the Nushell script:

```
modules/scripts/nix-mox.nu
```

### Usage

Run the script with Nushell (recommended Nushell 0.90+):

```bash
nu modules/scripts/nix-mox.nu -- --script install
```

> **Note:** Argument passing to Nushell scripts may vary by Nushell version. If you see `[ERROR] No script specified`, your Nushell version may not support argument passing to scripts. See the script comments for how to hardcode arguments for testing.

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

- `nix-mox.nu`         — Main automation entrypoint (Nushell)
- `common.nu`          — Shared utilities and logging
- `linux/`             — Linux-specific scripts (install, update, zfs, etc.)
- `windows/`           — Windows-specific scripts
- `testing/`           — Test infrastructure and helpers
- `lib/`               — Script libraries and helpers

## Script Development

- Use the utilities in `common.nu` for logging, error handling, and platform detection.
- Follow the argument parsing and error handling patterns in `nix-mox.nu` for new scripts.
- See the [Script Development Guide](../../docs/guides/scripting.md) for best practices and advanced usage.

## Troubleshooting

- If arguments are not passed to the script, try using the double dash (`--`) after the script path.
- For Nushell versions that do not support argument passing, you may need to hardcode arguments in the script for testing.
- If you see `[ERROR] No script specified`, check your Nushell version and invocation method.

## Example Invocations

```bash
# Install (dry run)
nu modules/scripts/nix-mox.nu -- --script install --dry-run

# Update packages
nu modules/scripts/nix-mox.nu -- --script update

# ZFS snapshot (Linux only)
nu modules/scripts/nix-mox.nu -- --script zfs-snapshot
``` 