# Safe NixOS Configuration Template

This template provides a complete NixOS configuration that integrates with nix-mox tools while preventing common display issues that can occur when services aren't properly configured.

## Key Features

- **Display Safety**: Explicitly enables display services to prevent CLI lock
- **nix-mox Integration**: Includes your nix-mox packages and development shells
- **Gaming Ready**: Steam enabled with proper graphics driver configuration
- **Development Friendly**: Includes common development tools and aliases

## Quick Start

1. **Create the configuration directory:**

   ```bash
   mkdir -p ~/nixos-config
   cd ~/nixos-config
   ```

2. **Copy the template files:**
   - `flake.nix`
   - `configuration.nix`
   - `home.nix`
   - `hardware-configuration.nix` (will be generated)

3. **Generate hardware configuration:**

   ```bash
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

4. **Update the configuration:**
   - Change "hydebox" to your desired hostname in both `flake.nix` and `configuration.nix`
   - Change "hyde" to your username throughout all files
   - Set your timezone in `configuration.nix`
   - Update git user info in `home.nix`
   - Choose your preferred desktop environment/window manager
   - Configure graphics drivers based on your hardware

5. **Build and switch:**

   ```bash
   sudo nixos-rebuild switch --flake .#hydebox
   ```

## Configuration Options

### Display Managers

Choose one display manager in `configuration.nix`:

```nix
displayManager = {
  lightdm.enable = true;  # Lightweight
  # sddm.enable = true;   # KDE's display manager
  # gdm.enable = true;    # GNOME's display manager
};
```

### Desktop Environments

Choose one desktop environment:

```nix
desktopManager = {
  gnome.enable = true;     # GNOME
  # plasma5.enable = true; # KDE Plasma
  # xfce.enable = true;    # XFCE (lightweight)
};
```

### Window Managers

Or use a window manager instead:

```nix
windowManager.i3.enable = true;
# windowManager.awesome.enable = true;
```

### Graphics Drivers

Uncomment the appropriate driver section:

**NVIDIA:**

```nix
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  open = false;
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};
```

**AMD:**

```nix
services.xserver.videoDrivers = [ "amdgpu" ];
```

## Using nix-mox After Setup

### System Packages

Your nix-mox packages are available system-wide:

```bash
proxmox-update
vzdump-backup
zfs-snapshot
nixos-flake-update
```

### Development Shells

Access dev shells via aliases:

```bash
dev-default      # Opens default development shell
dev-development  # Opens development tools shell
dev-testing      # Opens testing shell
dev-services     # Opens services shell
dev-monitoring   # Opens monitoring shell
dev-gaming       # Opens gaming development shell (Linux x86_64 only)
dev-zfs          # Opens ZFS tools shell (Linux only)
```

Or directly:

```bash
nix develop github:Hydepwns/nix-mox#default
nix develop github:Hydepwns/nix-mox#development
nix develop github:Hydepwns/nix-mox#testing
nix develop github:Hydepwns/nix-mox#services
nix develop github:Hydepwns/nix-mox#monitoring
nix develop github:Hydepwns/nix-mox#gaming
nix develop github:Hydepwns/nix-mox#zfs
```

## Troubleshooting

### Display Issues

If display still doesn't work after switching:

1. Check logs: `journalctl -b -u display-manager`
2. Try a different display manager (sddm or gdm instead of lightdm)
3. Ensure graphics drivers match your hardware
4. Try a minimal window manager (like i3) instead of a full DE

### Rollback

To rollback if something goes wrong:

```bash
sudo nixos-rebuild switch --rollback
```

## Customization

### Adding More Packages

Add packages to `environment.systemPackages` in `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  # Your packages here
  vim
  git
  # ... more packages
];
```

### Custom Services

Add services to the `services` section in `configuration.nix`:

```nix
services = {
  # Your services here
  openssh.enable = true;
  # ... more services
};
```

### Shell Aliases

Add custom aliases in `home.nix`:

```nix
shellAliases = {
  # Your aliases here
  ll = "ls -l";
  # ... more aliases
};
```

## Security Notes

- SSH is configured with password authentication disabled
- Firewall is enabled by default
- Root login is disabled
- Only trusted binary caches are configured

## Performance

- Uses nix-mox's binary caches for faster builds
- Automatic garbage collection configured
- Auto-optimize store enabled
- Latest kernel packages for better hardware support
