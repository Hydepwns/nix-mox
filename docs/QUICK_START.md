# Quick Start Guide

> Get started with nix-mox in minutes.

## Prerequisites

- **NixOS** (fresh install with working display and user account)
- Basic shell access (no additional packages required initially)

## Safe Setup Process

**Critical**: This framework modifies your NixOS system. Follow these steps exactly to prevent boot failures.

```bash
# 1. Clone repository  
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# 2. FIRST: Check bootstrap requirements (works without make/nushell)
./bootstrap-check.sh

# 3. Install missing prerequisites (if bootstrap-check.sh shows failures)
nix-shell -p git nushell

# 4. MANDATORY: Run safety validation before any changes
nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu --verbose"

# 5. Choose your setup method:
```

## 🎯 **Setup Options - Choose Your Favorite Parts**

### **Option 1: Quick Favorites (Recommended)**
Fast setup with popular preset configurations:

```bash
# Browse available presets
nix-shell -p nushell --run "nu scripts/setup/quick-favorites.nu"

# Apply a specific preset
nix-shell -p nushell --run "nu scripts/setup/quick-favorites.nu dev-gaming"
nix-shell -p nushell --run "nu scripts/setup/quick-favorites.nu productivity"
nix-shell -p nushell --run "nu scripts/setup/quick-favorites.nu gaming-only"
```

**Available Presets:**
- `dev-gaming` - Developer Gaming Rig (development + gaming)
- `productivity` - Productivity Workstation (office + communication)
- `gaming-only` - Pure Gaming Machine (all gaming platforms)
- `dev-server` - Development Server (server + development)
- `minimal-dev` - Minimal Development (lightweight dev tools)
- `media-center` - Media Center (entertainment + media)

### **Option 2: Enhanced Setup (Granular Control)**
Choose specific components you want:

```bash
# Interactive component selection
nix-shell -p nushell --run "nu scripts/setup/enhanced-setup.nu"
```

**Component Categories:**
- **Development Tools**: IDEs, compilers, debuggers
- **Gaming & Entertainment**: Gaming platforms, performance tools, media
- **Productivity & Communication**: Office apps, messaging, utilities
- **System & Security**: Monitoring, security, networking

### **Option 3: Component Browser (Explore First)**
Browse and preview available components:

```bash
# Browse all components
nix-shell -p nushell --run "nu scripts/setup/component-browser.nu"

# Explore specific categories
nix-shell -p nushell --run "nu scripts/setup/component-browser.nu --category development"
nix-shell -p nushell --run "nu scripts/setup/component-browser.nu --category gaming"

# Get detailed component information
nix-shell -p nushell --run "nu scripts/setup/component-browser.nu --category gaming --component platforms"
```

### **Option 4: Traditional Setup (Legacy)**
Original template-based setup:

```bash
# Unified setup (recommended - all features)
nix-shell -p nushell --run "nu scripts/setup/unified-setup.nu"

# Manual setup alternative
cp env.example .env
nano .env
```

## Choose Your Template (Traditional Method)

```bash
# Development environment
cp config/templates/development.nix config/nixos/configuration.nix

# Gaming workstation
cp config/templates/gaming.nix config/nixos/configuration.nix
# Note: For modular gaming configuration, use:
# Gaming is now handled via the gaming subflake in flake.nix
# And import ./gaming/default.nix in your configuration.nix

# Server setup
cp config/templates/server.nix config/nixos/configuration.nix

# Minimal system
cp config/templates/minimal.nix config/nixos/configuration.nix
```

## 🚀 **Build and Apply Configuration**

```bash
# 6. Validate configuration before rebuilding
nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu"

# 7. NEVER use direct nixos-rebuild - use safe wrapper instead:
nix-shell -p nushell --run "nu scripts/maintenance/safe-rebuild.nu --backup --test-first"

# 8. If you MUST use direct nixos-rebuild, always test first:
# sudo nixos-rebuild dry-activate --flake .#nixos  # Test first  
# sudo nixos-rebuild switch --flake .#nixos        # Apply if dry-run succeeds
```

## 🎮 **Access Your Favorite Parts**

After setup, access your selected components:

### **Development Tools**
```bash
# Enter development environment
nix develop .#development

# Launch IDEs
vscode
cursor
vim

# Use programming languages
rustc --version
python3 --version
node --version
```

### **Gaming Platforms**
```bash
# Enter gaming environment
nix develop .#gaming

# Launch gaming platforms
steam
lutris
heroic

# Performance monitoring
gamemode
mangohud
```

### **Productivity Tools**
```bash
# Office applications
libreoffice
obsidian
joplin

# Communication
discord
signal-desktop
telegram-desktop
thunderbird
```

### **System Tools**
```bash
# Monitoring
htop
btop
neofetch

# Security
ufw
gpg

# Networking
tailscale
```

## 📚 **Next Steps**

See [Templates](TEMPLATES.md) for detailed information about each template.

For advanced configuration options, see the [Configuration Guide](CONFIGURATION.md).

## 🆘 **Troubleshooting**

If you encounter issues:

1. **Check the logs**: `journalctl -xe`
2. **Validate configuration**: `nix flake check`
3. **Test configuration**: `sudo nixos-rebuild dry-activate --flake .#nixos`
4. **Rollback if needed**: `sudo nixos-rebuild switch --rollback`

For more help, see the [Troubleshooting Guide](TROUBLESHOOTING.md).
