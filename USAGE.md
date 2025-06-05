# Usage & Deployment Guide

This project provides automation scripts and infrastructure templates for NixOS, Proxmox, containers, and monitoring.  
**To deploy, follow the quick start below.**

---

## Table of Contents

- [Quick Start: Deploying This Project](#-quick-start-deploying-this-project)
- [Legacy/Manual Install (Non-NixOS only)](#legacymanual-install-non-nixos-only)
- [Using the NixOS Modules (Optional)](#using-the-nixos-modules-optional)
  - [Common Module](#common-module)
  - [ZFS Auto-Snapshot Module](#zfs-auto-snapshot-module)
  - [Infisical Secrets Module](#infisical-secrets-module)
  - [Tailscale Module](#tailscale-module)
- [What's Next?](#whats-next)
- [Usage & Reference](#usage--reference)
  - [Minimal Usage](#minimal-usage)
  - [Available Scripts](#available-scripts)
  - [Available Templates](#available-templates)
  - [Advanced Usage & Guides](#advanced-usage--guides)
- [Install & Uninstall](#install--uninstall)

---

## 🚀 Quick Start: Deploying This Project

### 1. Clone the Repository

```bash
git clone https://github.com/hydepwns/nix-mox.git
cd nix-mox
```

### 2. Nix Flake Usage (Recommended for Nix/NixOS users)

- Run any script directly:

  ```bash
  nix run .#proxmox-update
  nix run .#zfs-snapshot
  nix run .#nixos-flake-update
  # ...etc
  ```

- Install a script to your user profile:

  ```bash
  nix profile install .#proxmox-update
  # ...etc
  ```

- See all available scripts in flake.nix or by running `nix flake show`.

### 3. Use a Template

Templates for containers, VMs, monitoring, and storage are available in the `templates/` directory.

**For all template usage, customization, and best practices, see [templates/USAGE.md](templates/USAGE.md).**

### 4. Run a Script Directly (Manual/Legacy)

- You can still run any script manually (not recommended for NixOS):

  ```bash
  sudo ./scripts/linux/proxmox-update.sh
  ```

- Or use the legacy install scripts (see below).

---

## Legacy/Manual Install (Non-NixOS only)

> **Warning:** The install.sh and uninstall.sh scripts are deprecated for NixOS users. Use Nix flake methods above instead.

- To install all scripts manually:

  ```bash
  sudo ./scripts/linux/install.sh
  ```

- To remove/uninstall:

  ```bash
  sudo ./scripts/linux/uninstall.sh
  ```

---

## Using the NixOS Modules (Optional)

This project provides several NixOS modules to declaratively manage system services. To use them, add the flake to your inputs and import the desired modules.

1. **Add the flake input** to your `flake.nix`:

    ```nix
    {
      inputs.nix-mox.url = "github:hydepwns/nix-mox";
      # ...
    }
    ```

2. **Import the modules** in your NixOS configuration:

    ```nix
    # In your configuration.nix or other imported file
    {
      imports = [
        nix-mox.nixosModules.nix-mox
        nix-mox.nixosModules.zfs-auto-snapshot
        nix-mox.nixosModules.infisical
        nix-mox.nixosModules.tailscale
      ];
    }
    ```

All module options are available under the `services.nix-mox` namespace.

### Common Module

The common module installs all `nix-mox` scripts and sets up a systemd timer for automatic flake updates.

- **Enable the module**:

    ```nix
    {
      services.nix-mox.common.enable = true;
    }
    ```

- **This will**:
  - Add all `nix-mox` scripts to `environment.systemPackages`.
  - Set up a systemd timer/service for `nixos-flake-update` (runs daily as root).

### ZFS Auto-Snapshot Module

This module declaratively manages ZFS snapshots and retention.

1. **Enable and configure the module**:
    Define which pools or datasets to snapshot, how often, and the retention period in days.

    ```nix
    services.nix-mox.zfs-auto-snapshot = {
      enable = true;
      pools = {
        # Snapshot 'rpool' hourly and keep for 7 days
        "rpool" = {
          frequency = "hourly";
          retention_days = 7;
        };

        # Snapshot a specific dataset daily and keep for 30 days
        "rpool/data/documents" = {
          frequency = "daily";
          retention_days = 30;
        };

        # Disable snapshots for a specific dataset if inherited
        "rpool/data/cache" = {
          enable = false;
        };
      };
    };
    ```

2. After rebuilding your system, systemd timers will be created to automatically take and prune snapshots according to your configuration.

### Infisical Secrets Module

This module declaratively manages secrets with Infisical, fetching them and making them available as environment files.

1. **Provide the Infisical token** (e.g., via `sops-nix`):

    ```nix
    {
      # Provide the Infisical token securely (e.g., using sops-nix)
      sops.secrets.infisical_token = {
        # sops-nix configuration...
      };
    }
    ```

2. **Enable and configure the service**:
    Define which secrets to fetch for different projects and environments.

    ```nix
    services.nix-mox.infisical = {
      enable = true;
      tokenFile = config.sops.secrets.infisical_token.path;

      # Define sets of secrets to fetch
      secrets = {
        # For a 'my-app' service
        "my-app" = {
          project = "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890";
          environment = "prod";
          path = "/run/secrets/my-app.env";
        };

        # For a 'grafana' service, with a custom refresh timer
        "grafana" = {
          project = "b2c3d4e5-f6a1-b2c3-d4e5-f6a1b2c3d4e5";
          environment = "staging";
          path = "/run/secrets/grafana.env";
          update_timer = {
            enable = true;
            frequency = "hourly"; # Refresh secrets hourly
          };
        };
      };
    };
    ```

3. **Use the secrets in other services**:
    After rebuilding, the secrets will be available at the specified paths. You can use them in other systemd services.

    ```nix
    systemd.services.my-app = {
      # ...
      serviceConfig = {
        EnvironmentFile = config.services.nix-mox.infisical.secrets."my-app".path;
        # ...
      };
    };
    ```

### Tailscale Module

This module simplifies enabling and configuring Tailscale.

1. **Enable the module**:

    ```nix
    {
      services.nix-mox.tailscale.enable = true;
    }
    ```

2. **For headless machines**, you can pre-authorize the node by providing an auth key. This is useful for servers that you can't log into interactively.

    Create a file with your Tailscale auth key and secure it (e.g., with `sops-nix`):

    ```nix
    # In your configuration, provide the path to the auth key file
    sops.secrets.tailscale_auth_key = {
      # sops-nix configuration...
    };

    services.nix-mox.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    };
    ```

3. After rebuilding your system, Tailscale will be enabled. If an `authKeyFile` is provided, the node will attempt to authenticate on its first boot.

---

## What's Next?

- For advanced usage, see the [guides below](#advanced-usage--guides).
- For details on each script and template, see the sections below.

---

# Usage & Reference

## Minimal Usage

- **Run a script:**

  ```bash
  nix run .#<script-name>         # Preferred (Nix/NixOS)
  sudo ./scripts/linux/<script>.sh # Manual/legacy
  ```

- **Use a template:**
  See [templates/USAGE.md](templates/USAGE.md) for all template usage and best practices.

## Available Scripts

- `proxmox-update.sh` — Update and upgrade Proxmox host packages safely.
- `vzdump-backup.sh` — Backup all Proxmox VMs and containers to specified storage.
- `zfs-snapshot.sh` — Create and prune ZFS snapshots for the specified pool.
- `nixos-flake-update.sh` — Update flake inputs and rebuild NixOS system.
- `install.sh` — Legacy/compat install logic for nix-mox scripts (deprecated for NixOS).
- `uninstall.sh` — Legacy/compat uninstall logic for nix-mox scripts (deprecated for NixOS).
- `install-steam-rust.nu` — NuShell script to automate Steam installation and prompt for Rust installation on first boot.
- `run-steam-rust.bat` — Batch wrapper to launch the NuShell script via Windows Task Scheduler.
- `InstallSteamRust.xml` — Windows Scheduled Task definition to run the automation at user logon.

## Available Templates

- `containers/docker/` — Docker container examples
- `containers/lxc/` — LXC container examples
- `monitoring/grafana/` — Grafana dashboards
- `nixos-vm-template/` — NixOS VM template
- `zfs-ssd-caching/` — ZFS SSD caching example

**For usage and customization, see [templates/USAGE.md](templates/USAGE.md).**

## Advanced Usage & Guides

For detailed guides on more advanced topics, see the following documents:

- **[📄 NixOS on Proxmox](./docs/nixos-on-proxmox.md)**:
  Deploying NixOS as a VM or LXC container on Proxmox.

- **[📄 Windows on Proxmox](./docs/windows-on-proxmox.md)**:
  Best practices for creating and configuring a Windows VM.

- **[📄 Windows Automation Guide](./docs/windows-automation-guide.md)**:
  Automate the installation of Steam and Rust on a Windows system.

- **[📄 Advanced Configuration](./docs/advanced-configuration.md)**:
  Guides for networking, shared storage, security, and monitoring.

---

## Install & Uninstall

> **Warning:** The install.sh and uninstall.sh scripts are deprecated for NixOS users. Use Nix flake methods above instead.

To install all automation scripts and set up systemd timers, run:

```bash
sudo ./scripts/install.sh
```

To remove all installed scripts and timers, run:

```bash
sudo ./scripts/uninstall.sh
```
