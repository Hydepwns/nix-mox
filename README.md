# nix-mox: Proxmox, NixOS, Windows automation

Terse, reproducible automation for Proxmox, NixOS, and Windows. See [USAGE.md](USAGE.md) for details.

---

## Quick Start

1. Clone:

   ```bash
   git clone https://github.com/hydepwns/nix-mox.git && cd nix-mox
   ```

2. **Nix Flake Usage (Recommended for Nix/NixOS users):**

   - Run any script directly:

     ```bash
     nix run .#proxmox-update
     nix run .#zfs-snapshot
     # ...etc
     ```

   - Install a script to your user profile:

     ```bash
     nix profile install .#proxmox-update
     # ...etc
     ```

   - See [USAGE.md](USAGE.md) for more details and all available scripts.

3. **Legacy/Manual Install (Non-NixOS only):**
   - The install.sh/uninstall.sh scripts are deprecated for NixOS users.
   - For legacy/manual install instructions, see [USAGE.md](USAGE.md).

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

See [USAGE.md](USAGE.md) for more details.
