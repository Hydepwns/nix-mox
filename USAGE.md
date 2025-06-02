# Usage & Deployment Guide

This project provides automation scripts and infrastructure templates for NixOS, Proxmox, containers, and monitoring.  
**To deploy, follow the quick start below.**

---

## 🚀 Quick Start: Deploying This Project

### 1. Clone the Repository

```bash
git clone https://github.com/hydepwns/nix-mox.git
cd nix-mox
```

### 2. Install All Automation Scripts

This sets up systemd timers and automation for Proxmox, ZFS, and NixOS.

```bash
sudo ./scripts/install.sh
```

- To remove/uninstall:  

  ```bash
  sudo ./scripts/uninstall.sh
  ```

### 3. Use a Template

Copy any template from `templates/` to your infrastructure repo or host, then customize as needed.

```bash
cp -r templates/containers/docker/my-example/ ~/my-infra/
# Edit files as needed, then deploy using your preferred method (e.g., docker-compose, lxc, etc.)
```

### 4. Run a Script Directly

You can run any script manually:

```bash
sudo ./scripts/proxmox-update.sh
```

Or, if you use Nix flakes:

```bash
nix run .#proxmox-update
```

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
  sudo ./scripts/<script>.sh
  # or via Nix flake:
  nix run .#<script-name>
  ```

- **Use a template:**
  Copy from `templates/` to your infra, edit as needed.

## Available Scripts

- `proxmox-update.sh` — Update Proxmox host
- `vzdump-backup.sh` — Backup VMs/CTs
- `zfs-snapshot.sh` — ZFS snapshot/prune
- `nixos-flake-update.sh` — Update NixOS flake
- `install.sh` / `uninstall.sh` — Install/uninstall all automation

## Available Templates

- `containers/docker/` — Docker container examples
- `containers/lxc/` — LXC container examples
- `monitoring/grafana/` — Grafana dashboards
- `nixos-vm-template/` — NixOS VM template
- `zfs-ssd-caching/` — ZFS SSD caching example

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
