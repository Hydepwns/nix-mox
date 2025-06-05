# nix-mox: Proxmox, NixOS, & Windows Automation

Terse, reproducible, and opinionated automation for Proxmox, NixOS, and Windows.

This repository provides a set of scripts, NixOS modules, and templates to streamline the management of a home server environment running Proxmox, with a focus on declarative systems using NixOS and automated setups for Windows VMs.

- **Usage & Install Instructions:** See [USAGE.md](./USAGE.md)
- **Architecture & Design:** See [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## 🌟 Features

- **🚀 Nix-Powered Automation**:
  - Run scripts for Proxmox maintenance (`proxmox-update`), ZFS snapshots (`zfs-snapshot`), and backups (`vzdump-backup`) directly with `nix run`.
  - Update your NixOS systems with a single command: `nix run .#nixos-flake-update`.
  - Use the included NixOS module to make all scripts and a daily flake update service available system-wide.
- **🖥️ Windows VM Automation**:
  - Automate Steam and Rust installation on a Windows VM using a NuShell script, perfect for setting up gaming VMs.
  - Deploy the automation to run on user login with a pre-configured Windows Scheduled Task.
- **📂 Declarative Templates**:
  - Deploy NixOS as a lightweight LXC container or a fully declarative VM.
  - Examples for ZFS caching, Docker/LXC containers, and Grafana monitoring dashboards.
- **🛠️ Developer Environment**:
  - Get a consistent and reproducible development environment with `nix develop`, which provides all the tools needed to work on this repository.

## 🚀 Quick Start

1. **Clone the repository**:

    ```bash
    git clone https://github.com/hydepwns/nix-mox.git
    cd nix-mox
    ```

2. **Explore and run scripts**:

    ```text
    # See what's available
    nix flake show

    # Run a script
    nix run .#proxmox-update
    ```

3. **Review the Documentation**:
    - For all usage, installation, and module instructions, see [**USAGE.md**](./USAGE.md).
    - For a high-level overview of the setup, see [**ARCHITECTURE.md**](./ARCHITECTURE.md).

---

## About

nix-mox provides automation scripts and templates for:

- Proxmox host management
- NixOS system updates and deployment
- Windows automation (Steam, Rust, etc.)
- Container and monitoring templates

It leverages Nix Flakes for easy script execution (e.g., `nix run .#proxmox-update`) and a consistent development environment (`nix develop`).
