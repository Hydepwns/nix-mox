# Proxmox + NixOS + Windows: Quick Reference

_This is a quick reference for setting up Proxmox + NixOS + Windows. For full usage and reference, see [USAGE.md](USAGE.md)._

---

## Table of Contents

- [Getting Started](#getting-started)
- [Requirements](#requirements)
- [Directory Structure](#directory-structure)
- [Flake Outputs](#flake-outputs)
- [Quick Start](#quick-start)
- [Install & Uninstall Automation](#install--uninstall-automation)
- [Usage & Reference](#usage--reference)
- [Architecture Overview](#architecture-overview)
- [Using This Flake as a Package Source](#using-this-flake-as-a-package-source)

---

## Getting Started

1. Review [ARCHITECTURE.md](ARCHITECTURE.md) for system overview.
2. Clone the repo and review scripts and configuration files.
3. Follow the Quick Start below for setup.

## Requirements

- Proxmox VE (for virtualization)
- NixOS (for declarative Linux configuration)
- Bash shell (for running scripts)
- Systemd (for timers/services)
- Root privileges to install and run automation scripts

## Directory Structure

- `scripts/` — Automation scripts for Proxmox, NixOS, Windows
- `ARCHITECTURE.md` — System diagrams and hardware overview
- `README.md` — Main documentation and usage
- `flake.nix` — Nix flake for NixOS config
- `nixos-flake-update.*` — Systemd timer/service for NixOS updates

## Flake Outputs

- **devShells.default**: Development shell with common tools (git, nix, bash, shellcheck)
- **formatter**: Nix code formatter (nixpkgs-fmt)
- **nixosConfigurations.example**: Example NixOS configuration
- **packages.<system>.proxmox-update**: Proxmox update script as a Nix package
- **packages.<system>.vzdump-backup**: Proxmox vzdump backup script as a Nix package
- **packages.<system>.zfs-snapshot**: ZFS snapshot/prune script as a Nix package
- **packages.<system>.nixos-flake-update**: NixOS flake update script as a Nix package

## Quick Start

1. **Clone the repository:**

   ```bash
   git clone https://github.com/hydepwns/nix-mox.git
   cd nix-mox
   ```

2. **Review and edit scripts and configuration files as needed for your environment.**
3. **Make scripts executable:**

   ```bash
   chmod +x scripts/*.sh
   ```

4. **Deploy scripts:**
   - **Proxmox:** Copy relevant scripts (e.g., `proxmox-update.sh`, `vzdump-backup.sh`, `zfs-snapshot.sh`) to `/usr/local/sbin/` or `/root/`.
   - **NixOS:** Copy `nixos-flake-update.sh` to `/etc/nixos/`.
   - **Windows Automation:** See [USAGE.md](USAGE.md#automated-steam--rust-installation-on-windows-nushell) for details on copying Windows-related scripts.
5. **Set up systemd timers and cron jobs as described below.**
6. **Run scripts manually to verify setup:**

   ```bash
   sudo ./scripts/proxmox-update.sh
   sudo ./scripts/zfs-snapshot.sh
   sudo ./scripts/vzdump-backup.sh
   sudo ./scripts/nixos-flake-update.sh
   ```

> **Note:** Most scripts require root privileges. Use `sudo` as shown above.

## Install & Uninstall Automation

To install all automation scripts and set up systemd timers for automatic updates and backups, run:

```bash
sudo ./scripts/install.sh
```

To remove all installed scripts and timers, run:

```bash
sudo ./scripts/uninstall.sh
```

> **Note:** scripts require root.

See [USAGE.md](USAGE.md) for more details.

---

## Usage & Reference

See [USAGE.md](USAGE.md) for detailed usage instructions: VM/container setup, networking, storage, automation scripts, etc.

## Architecture Overview

See [ARCHITECTURE.md](ARCHITECTURE.md) for diagrams and a high-level overview of the system architecture, network topology, storage layout, update and backup flow, and hardware details.

## Using This Flake as a Package Source

You can use this repository as a Nix flake to run or develop with the included automation scripts, without manual copying or installation.

- **Run the default script (Proxmox update):**

  ```bash
  nix run .\
  # or explicitly
  nix run .#proxmox-update
  ```

- **Run any script as a package:**

  ```bash
  nix run .#<script-name>
  # Example: backup all VMs/CTs
  nix run .#vzdump-backup
  # Example: take/prune ZFS snapshots
  nix run .#zfs-snapshot
  # Example: update NixOS flake
  nix run .#nixos-flake-update
  ```

- **Get a development shell with all tools:**

  ```bash
  nix develop
  ```

- **Format Nix code:**

  ```bash
  nix fmt
  ```

> See the script headers and USAGE.md for options like --dry-run, --help, etc.
