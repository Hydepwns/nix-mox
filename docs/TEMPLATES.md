# Templates & Profiles

> Quick reference for nix-mox templates and profiles.

## Quick Template Selection

```bash
# Choose your template
cp config/templates/development.nix config/nixos/configuration.nix
cp config/templates/gaming.nix config/nixos/configuration.nix
# Note: For modular gaming configuration, use:
# cp -r config/nixos/gaming/ config/nixos/
# And import ./gaming/default.nix in your configuration.nix
cp config/templates/minimal.nix config/nixos/configuration.nix
cp config/templates/server.nix config/nixos/configuration.nix
```

## Available Templates

| Template | Use Case | Includes |
|----------|----------|----------|
| `minimal` | Basic system | Essential tools, Plasma 6, SDDM |
| `development` | Software development | IDEs, containers, dev tools |
| `gaming` | Gaming workstation | Steam, performance optimizations |
| `server` | Production server | Monitoring, management tools |

## Template Details

### Minimal Template

- **Base system** with essential tools
- **KDE Plasma 6** desktop environment
- **SDDM** display manager
- **Kitty** terminal emulator
- **Basic networking** and security

### Development Template

- **All minimal features** plus:
- **Development tools**: VSCode, Docker, Git
- **Programming languages**: Node.js, Python, Rust, Go
- **Build tools**: CMake, Ninja, Meson
- **Debugging tools**: GDB, LLDB, Valgrind
- **Container support**: Docker, Docker Compose

### Gaming Template

- **All minimal features** plus:
- **Gaming platforms**: Steam, Lutris, Heroic
- **Performance tools**: GameMode, MangoHud, GOverlay
- **Graphics optimizations**: NVIDIA/AMD/Intel support
- **Audio**: PipeWire with gaming optimizations
- **Voice chat**: Discord, TeamSpeak, Mumble

### Server Template

- **No desktop environment** (headless)
- **Server management**: htop, iotop, monitoring tools
- **Container tools**: Docker, Podman, Kubernetes
- **Web servers**: Nginx, Apache
- **Database tools**: PostgreSQL, Redis, MongoDB
- **Security hardening**: Firewall, auditd, AppArmor

## Profiles

Templates use these shared profiles:

- **`base.nix`**: Common system config, Plasma 6, SDDM
- **`security.nix`**: Security hardening, firewall, SSH
- **`development.nix`**: Development tools and environments
- **`gaming/`**: Modular gaming configuration (recommended)
  - `default.nix`: Main entry point
  - `options.nix`: Option definitions
  - `hardware.nix`: Hardware configuration
  - `audio.nix`: Audio configuration
  - `performance.nix`: Performance optimizations
  - `platforms.nix`: Gaming platforms
  - `networking.nix`: Network configuration
  - `security.nix`: Security settings
- **`gaming.nix`**: Legacy monolithic gaming configuration
- **`server.nix`**: Server management and monitoring

## Customization

### Add Packages

```nix
# config/nixos/configuration.nix
environment.systemPackages = with pkgs; [
  # Your packages here
  vim git docker
];
```

### Enable Services

```nix
# config/nixos/configuration.nix
services = {
  nginx.enable = true;
  postgresql.enable = true;
};
```

### Override Desktop Environment

```nix
# config/nixos/configuration.nix
services = {
  desktopManager = {
    plasma6.enable = false;  # Disable Plasma 6
    gnome.enable = true;     # Enable GNOME instead
  };
};
```

## Multi-Host Management

For managing multiple hosts:

```bash
# Build specific host
nix build .#nixosConfigurations.host1.config.system.build.toplevel

# Deploy to host
nixos-rebuild switch --flake .#host1
```

See [Multi-Host Guide](archive/MULTI_HOST.md) for advanced configuration.
