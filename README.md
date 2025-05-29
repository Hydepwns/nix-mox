# nix-mox: Proxmox, NixOS, Windows automation

Terse, reproducible automation for Proxmox, NixOS, and Windows. See [USAGE.md](USAGE.md) for details.

---

## Quick Start

1. Clone:

   ```bash
   git clone https://github.com/hydepwns/nix-mox.git && cd nix-mox
   ```

2. Review/edit scripts in `scripts/` and templates in `templates/`.
3. (Optional) Install all automation:

   ```bash
   sudo ./scripts/install.sh
   ```

4. See [USAGE.md](USAGE.md) for more.

---

## Directory Structure

- `scripts/` — Automation scripts (Linux, Windows)
- `templates/` — VM/container, monitoring, storage templates
- `flake.nix` — Nix flake config
- `ARCHITECTURE.md` — System overview

## Flake Outputs (short)

- `devShells.default`: Dev shell
- `formatter`: Nix formatter
- `nixosConfigurations.*`: Example configs
- `packages.*`: Automation scripts as Nix packages

---

## More

- See [USAGE.md](USAGE.md) for usage, scripts, and templates.
- See [ARCHITECTURE.md](ARCHITECTURE.md) for system diagrams.
