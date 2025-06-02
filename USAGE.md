# Usage & Deployment Guide

This project provides automation scripts and infrastructure templates for NixOS, Proxmox, containers, and monitoring.  
**To deploy, follow the quick start below.**

---

## Table of Contents

- [Quick Start: Deploying This Project](#-quick-start-deploying-this-project)
- [Legacy/Manual Install (Non-NixOS only)](#legacymanual-install-non-nixos-only)
- [Using the NixOS Module (Optional)](#using-the-nixos-module-optional)
- [What's Next?](#whats-next)
- [Usage & Reference](#usage--reference)
  - [Minimal Usage](#minimal-usage)
  - [Available Scripts](#available-scripts)
  - [Available Templates](#available-templates)
  - [Advanced Usage](#advanced-usage)
    - [NixOS on Proxmox](#nixos-on-proxmox)
    - [Windows on Proxmox](#windows-on-proxmox)
    - [Networking](#networking)
    - [Shared Storage](#shared-storage)
    - [Security](#security)
    - [Monitoring & Updates](#monitoring--updates)
    - [Automation Scripts](#automation-scripts)
    - [Automated Steam + Rust Installation on Windows (NuShell)](#automated-steam--rust-installation-on-windows-nushell)
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

## Using the NixOS Module (Optional)

If you want all nix-mox scripts and the flake update timer/service available system-wide, you can enable the NixOS module:

1. Add the module to your NixOS configuration (flake-based example):

   ```nix
   {
     inputs.nix-mox.url = "github:hydepwns/nix-mox";
     # ...
   }
   # In your configuration.nix or flake:
   {
     imports = [ nix-mox.nixosModules.nix-mox ];
     services.nix-mox.enable = true;
   }
   ```

2. This will:
   - Add all nix-mox scripts to `environment.systemPackages`.
   - Set up a systemd timer/service for `nixos-flake-update` (runs daily as root).

---

## What's Next?

- For advanced usage, see [Advanced Usage](#advanced-usage).
- For Windows automation, see [Automated Steam + Rust Installation on Windows](#automated-steam--rust-installation-on-windows-nushell).
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

## Advanced Usage

## NixOS on Proxmox

### LXC (Container)

- Download LXD image: [Hydra](https://hydra.nixos.org/job/nixos/release-*/nixos.lxdContainerImage.x86_64-linux/latest)
- Upload via Proxmox UI → CT Templates
- Create:

  ```bash
  pct create <VMID> local:vztmpl/nixos-*.tar.xz \
    --ostype unmanaged --features nesting=1 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp
  ```

- Set root password, SSH keys

### VM (Declarative)

- Use [nixos-generators](https://github.com/nix-community/nixos-generators):

  ```nix
  { config, ... }: {
    imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];
    services.qemuGuest.enable = true;
  }
  ```

  ```bash
  nixos-generate -f proxmox -c configuration.nix
  ```

- Upload `.vma.zst`, create VM, attach disk
- Remote update:

  ```bash
  nixos-rebuild switch --flake .#vm --target-host root@proxmox
  ```

### Distroless NixOS (OCI/Container)

- Minimal image:

  ```nix
  pkgs.dockerTools.buildImage {
    name = "distroless-app";
    config = { Cmd = [ "${pkgs.nginx}/bin/nginx" "-g" "daemon off;" ]; };
  }
  ```

- Multi-stage:

  ```nix
  let buildEnv = pkgs.buildEnv { ... };
      runtimeEnv = pkgs.runtimeOnlyDependencies buildEnv;
  in pkgs.dockerTools.buildImage { copyToRoot = runtimeEnv; }
  ```

- Flake config:

  ```nix
  outputs = { nixpkgs, ... }: {
    nixosConfigurations.my-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ({ ... }: {
        environment.systemPackages = with pkgs; [ nginx ];
        system.stateVersion = "24.11";
      }) ];
    };
  };
  ```

## Windows on Proxmox

- Create VM (UEFI, SCSI, VirtIO, attach ISOs)
- PCI passthrough (GPU):

  ```bash
  -device vfio-pci,host=01:00.0,multifunction=on
  ```

- QEMU guest agent

## Networking

- Bridges: vmbr0 (NixOS), vmbr1 (Windows), vmbr2 (Mgmt)
- Isolate traffic

## Shared Storage

- virtio-fs:

  ```nix
  virtualisation.sharedDirectories = {
    win-share = { source = "/mnt/windows"; target = "/win-mount"; };
  };
  ```

## Security

- Read-only rootfs:

  ```nix
  fileSystems."/".options = [ "ro" "nosuid" "nodev" ];
  ```

- Non-root services:

  ```nix
  users.users.nginx = { isSystemUser = true; group = "nginx"; };
  ```

- SBOM:

  ```bash
  nix store make-content-addressable /nix/store/...-nginx-* --rewrite-outputs > sbom.json
  ```

## Monitoring & Updates

- Unified logging:

  ```nix
  services.journald.extraConfig = ''
    ForwardToSyslog=yes
    MaxLevelSyslog=debug
  '';
  ```

- Auto-upgrade:

  ```nix
  system.autoUpgrade = {
    enable = true;
    flake = "github:user/nix-config#my-container";
    dates = "daily";
  };
  ```

## Automation Scripts

- See scripts in the `scripts/` directory for automation of Proxmox updates, vzdump backups, ZFS snapshots, and NixOS flake updates.

## Automated Steam + Rust Installation on Windows (NuShell)

Automate the installation of Steam and prompt for Rust (by Facepunch Studios, appid 252490) on a Windows system using NuShell and the provided scripts.

### Prerequisites

- A Windows system (VM or bare metal)
- [NuShell](https://www.nushell.sh/) installed (see below)
- The following files from [`scripts/`](scripts/):
  - [`install-steam-rust.nu`](scripts/install-steam-rust.nu)
  - [`run-steam-rust.bat`](scripts/run-steam-rust.bat)
  - [`InstallSteamRust.xml`](scripts/InstallSteamRust.xml)

### Steps

1. **Copy Scripts to Windows**  
   Copy the above files to a directory on your Windows system, e.g. `C:\scripts\`.

2. **Install NuShell**  
   If NuShell is not already installed, open PowerShell as Administrator and run:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; `
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   choco install nushell -y
   ```

   > **Note:** This will install `nu.exe` to `C:\Program Files\Nu\bin\nu.exe` by default.

3. **Register the Scheduled Task**  
   Open PowerShell as Administrator and run:

   ```powershell
   schtasks /Create /TN "InstallSteamRust" /XML "C:\scripts\InstallSteamRust.xml"
   ```

   > **Note:** This creates a scheduled task that runs at user logon and executes the NuShell script via the batch wrapper.

4. **First Logon Behavior**  
   On the next user logon, the following will happen automatically:
   - The NuShell script will download and silently install Steam.
   - Steam will be started once to initialize (you may see the login prompt).
   - The script will prompt you to log in to Steam and install Rust via the Steam client.

---

#### Optional: Remove the Task After First Run

To have the scheduled task delete itself after running once, add the following line to the end of [`install-steam-rust.nu`](scripts/install-steam-rust.nu):

```nu
run-external "schtasks.exe" "/Delete" "/TN" "InstallSteamRust" "/F"
```

#### Optional: Full Headless Rust Install

For a fully automated Rust install (no user interaction), you can use SteamCMD and provide Steam credentials. See the comments in [`install-steam-rust.nu`](scripts/install-steam-rust.nu) for a template, but be aware of the security risks of storing credentials in scripts.

---

This process allows you to prepare a Windows image that will automatically install Steam and prompt for Rust installation on first boot, making it easy to flash or deploy to new hardware or VMs.

## Install & Uninstall

To install all automation scripts and set up systemd timers, run:

```bash
sudo ./scripts/install.sh
```

To remove all installed scripts and timers, run:

```bash
sudo ./scripts/uninstall.sh
```

---

This process allows you to prepare a Windows image that will automatically install Steam and prompt for Rust installation on first boot, making it easy to flash or deploy to new hardware or VMs.
