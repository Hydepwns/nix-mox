# nix-mox Interactive Setup Wizard

> Zero-configuration system setup with intelligent recommendations

## 🎯 Overview

The interactive setup wizard provides a guided, 8-step process to configure your complete nix-mox system:

- **Platform detection** with automatic hardware optimization
- **User configuration** with intelligent defaults  
- **Feature selection** based on usage patterns
- **Storage configuration** with ZFS/Btrfs support
- **Network setup** with security hardening
- **Security configuration** with threat protection
- **Performance tuning** for your specific hardware
- **Final generation** of all configuration files

## 🚀 Quick Start

### Launch the Wizard
```bash
# Clone and navigate to nix-mox
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# Run the interactive setup wizard
nu scripts/core/interactive-setup.nu

# Follow the 8-step guided process
```

### What Gets Generated
The wizard creates:
- `config/nixos/configuration.nix` - Complete NixOS configuration
- `flake.nix` - Updated with your specific needs
- `scripts/setup-generated.nu` - Custom setup script
- `config/personal/generated.nix` - Your personal settings
- Hardware-specific optimizations and drivers

## 📋 Setup Process

### Step 1: Platform Detection & Hardware
```
🔍 Detecting platform and hardware...

Platform: linux (NixOS 24.05)
CPU: AMD Ryzen 9 7950X (16 cores, 32 threads)
RAM: 64 GB DDR5-5600
GPU: NVIDIA RTX 4090 (24GB VRAM)
Storage: 2TB NVMe SSD (Samsung 980 PRO)

Hardware optimizations available:
✅ CPU performance tuning for Ryzen 9000 series
✅ Memory optimization for 64GB+ systems  
✅ NVIDIA proprietary drivers with CUDA support
✅ NVMe power management tuning
✅ Gaming performance optimizations

Continue with detected configuration? [Y/n]:
```

**What this step does:**
- Detects CPU, GPU, RAM, and storage configuration
- Identifies available hardware optimizations
- Suggests performance tuning options
- Validates system compatibility

### Step 2: User Configuration
```
👤 User Configuration

Username: [current: droo]
Full Name: [Droo Pwns]
Email: [droo@example.com]
Shell: [zsh] (options: bash, zsh, fish, nu)
Editor: [nvim] (options: nvim, emacs, vscode, zed)
Terminal: [kitty] (options: kitty, alacritty, gnome-terminal)

Time Zone: [America/New_York]
Locale: [en_US.UTF-8]
Keyboard Layout: [us]

Enable dotfiles integration? [Y/n]:
Setup SSH keys automatically? [Y/n]:
```

**Configuration options:**
- Personal details for git and system
- Preferred development environment
- Localization settings  
- Integration with existing dotfiles
- SSH key generation and setup

### Step 3: Feature Selection
```
🎯 Feature Selection

Select your primary use case:
1. 🖥️  Desktop Workstation (GUI, multimedia, productivity)
2. 💻 Development Environment (IDEs, containers, languages)  
3. 🎮 Gaming Setup (Steam, performance optimization)
4. 🖥️  Server Configuration (headless, services, monitoring)
5. 🚀 CI/CD Runner (build tools, parallel execution)
6. 🎨 Creative Workstation (Blender, video editing, design)

Choice [1-6]: 2

📦 Development Features:
✅ Programming Languages (Rust, Go, Python, Node.js, Elixir)
✅ Development Tools (Docker, Git, Make, direnv)
✅ IDEs & Editors (VS Code, Zed, Neovim with LSP)
✅ Containers (Docker, Podman, Kubernetes tools)
✅ Databases (PostgreSQL, Redis, SQLite)
✅ API Tools (Postman, curl, httpie)

Additional features:
□ Machine Learning (PyTorch, TensorFlow, CUDA)
□ Mobile Development (Android SDK, Flutter)
□ Web Development (nginx, certbot, Let's Encrypt)
□ Monitoring (Prometheus, Grafana, AlertManager)

Select additional features [comma-separated]: 4
```

**Available feature sets:**
- **Desktop**: GUI applications, multimedia codecs, productivity tools
- **Development**: Programming languages, IDEs, build tools, containers
- **Gaming**: Steam, Wine, performance optimizations, RGB support
- **Server**: Headless setup, system services, remote management
- **CI/CD**: Build environments, testing tools, deployment utilities  
- **Creative**: Blender, GIMP, video editing, design tools

### Step 4: Storage Configuration
```
💾 Storage Configuration

Detected storage devices:
1. /dev/nvme0n1    2TB NVMe SSD (Samsung 980 PRO)
2. /dev/sda        4TB HDD (WD Black)

Filesystem recommendations:
🚀 NVMe SSD: ext4 with performance tuning
📦 HDD: Btrfs with compression and snapshots

Storage layout:
/          (root)      - 100GB on NVMe (ext4)
/home      (user data) - 500GB on NVMe (ext4)  
/nix       (packages)  - 200GB on NVMe (ext4)
/var/log   (logs)      - 20GB on NVMe (ext4)
/storage   (bulk data) - 4TB on HDD (Btrfs)

Enable ZFS instead? [y/N]:
Setup automatic snapshots? [Y/n]:
Configure backup destinations? [Y/n]:
```

**Storage options:**
- **Automatic partitioning** based on detected drives
- **Filesystem selection** (ext4, Btrfs, ZFS) with rationale
- **Snapshot configuration** for system recovery
- **Backup setup** to external drives or network
- **Performance tuning** for SSDs vs HDDs

### Step 5: Network Configuration
```
🌐 Network Configuration

Network Manager: NetworkManager (recommended)
Firewall: enabled with reasonable defaults

Detected network interfaces:
eth0    - Ethernet (1Gbps, connected)
wlan0   - WiFi (WiFi 6E, not connected)

SSH Configuration:
Port: 22
Allow root login: no
Password authentication: no (key-only)
Fail2ban protection: enabled

VPN Configuration:
□ WireGuard VPN server
□ OpenVPN client
□ Tailscale mesh networking

Additional services:
□ mDNS/Avahi (local network discovery)
□ Network monitoring (ntopng)
□ Bandwidth monitoring (vnstat)

Select network services [comma-separated]:
```

**Network features:**
- **Interface management** with NetworkManager/systemd-networkd
- **Firewall configuration** with nftables/iptables
- **SSH hardening** with key-based auth and fail2ban
- **VPN setup** for secure remote access
- **Network monitoring** and diagnostics

### Step 6: Security Configuration
```
🔒 Security Configuration

Security level: Enhanced (recommended for desktop)

Core security features:
✅ Automatic security updates
✅ Firewall with intrusion detection
✅ AppArmor/SELinux hardening
✅ Fail2ban brute-force protection
✅ USB/Bluetooth security policies

Additional security:
□ Full disk encryption (LUKS)
□ TPM 2.0 integration
□ Secure boot setup
□ Hardware security keys (YubiKey)
□ Network intrusion detection (Suricata)
□ File integrity monitoring (AIDE)

Browser hardening:
✅ Firefox with privacy extensions
✅ DNS over HTTPS (Cloudflare)
✅ Ad/tracker blocking (uBlock Origin)

Select additional security features [comma-separated]: 1,2
```

**Security levels:**
- **Basic**: Essential protections for low-risk environments
- **Enhanced**: Recommended for desktop/development systems
- **Hardened**: Maximum security for sensitive environments
- **Custom**: Fine-grained control over all security features

### Step 7: Performance Tuning
```
⚡ Performance Configuration

System profile: High Performance (desktop/gaming)

CPU Configuration:
Governor: performance (turbo boost enabled)
Scheduler: CFS with performance tuning
Thread affinity: automatic NUMA optimization

Memory Configuration:
Swappiness: 10 (prefer RAM over swap)
Dirty ratio: 15% (balance responsiveness/throughput)
Transparent hugepages: madvise

Storage Performance:
I/O scheduler: mq-deadline (SSD optimized)
Read-ahead: 256KB for NVMe
Discard/TRIM: automatic and periodic

Graphics Performance:
GPU drivers: NVIDIA proprietary (495.46)
CUDA toolkit: 11.8
Vulkan support: enabled
Hardware acceleration: enabled

Gaming optimizations:
□ GameMode for automatic game optimization
□ Low-latency kernel (Linux-zen)
□ Real-time priority for games
□ GPU overclocking profiles

Select gaming optimizations [comma-separated]:
```

**Performance profiles:**
- **Power Save**: Laptop/battery optimization
- **Balanced**: Good performance with efficiency  
- **High Performance**: Maximum performance for desktops
- **Gaming**: Optimized for low latency and high FPS
- **Server**: Throughput and stability focused

### Step 8: Final Configuration & Generation
```
🎉 Configuration Summary

Platform: linux (NixOS 24.05)
Profile: Development + Gaming
User: droo (Droo Pwns)
Features: 47 packages, 12 services
Storage: NVMe + HDD with Btrfs snapshots
Network: NetworkManager + SSH hardening
Security: Enhanced with disk encryption
Performance: High performance + gaming optimizations

Estimated build time: 15-20 minutes
Download size: ~2.1 GB
Installation size: ~8.3 GB

Generated files:
✅ config/nixos/configuration.nix (1,247 lines)
✅ flake.nix (updated with 23 inputs)
✅ scripts/setup-generated.nu (312 lines)
✅ config/personal/droo.nix (156 lines)
✅ Hardware configuration detected and saved

Ready to build? [Y/n]: Y

🔨 Building NixOS configuration...
```

**Final generation includes:**
- Complete NixOS configuration with all selected features
- Hardware-specific optimizations and drivers
- User environment with dotfiles integration
- Custom setup script for additional configuration
- Documentation of all choices made

## 🛠️ Advanced Options

### Custom Templates
```bash
# Use existing template as starting point
nu scripts/core/interactive-setup.nu --template development

# Save current config as template
nu scripts/core/interactive-setup.nu --save-template my-config
```

### Batch Configuration
```bash
# Use configuration file for unattended setup
nu scripts/core/interactive-setup.nu --config config/automated-setup.toml

# Generate config file from current setup
nu scripts/core/interactive-setup.nu --export-config
```

### Development Mode
```bash
# Test configuration without building
nu scripts/core/interactive-setup.nu --dry-run

# Verbose output for debugging
nu scripts/core/interactive-setup.nu --verbose
```

## 🔧 Configuration Files

### Generated Configuration Structure
```
config/
├── nixos/
│   ├── configuration.nix      # Main NixOS config
│   ├── hardware-configuration.nix  # Hardware detection
│   └── generated/
│       ├── features.nix       # Selected features
│       ├── performance.nix    # Performance tuning
│       └── security.nix       # Security hardening
├── personal/
│   ├── droo.nix              # User-specific config
│   └── dotfiles/             # Dotfiles integration
└── generated/
    ├── setup.nu              # Post-install setup script
    └── install-packages.nix  # Additional packages
```

### Customizing Generated Config
```nix
# config/nixos/configuration.nix
{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./generated/features.nix
    ./generated/performance.nix
    ./generated/security.nix
    ../personal/droo.nix
  ];

  # Wizard-generated configuration
  system.stateVersion = "24.05";
  networking.hostName = "nixos-desktop";
  
  # Your customizations here
  services.custom-service.enable = true;
}
```

## 🔍 Troubleshooting

### Wizard Issues

**1. Hardware detection fails:**
```bash
# Manual hardware configuration
sudo nixos-generate-config --root /mnt

# Use generated file in wizard
nu scripts/core/interactive-setup.nu --hardware-config hardware-configuration.nix
```

**2. Network connectivity problems:**  
```bash
# Test network before running wizard
ping google.com

# Use offline mode with local packages
nu scripts/core/interactive-setup.nu --offline
```

**3. Insufficient permissions:**
```bash
# Run wizard as regular user, not root
whoami  # Should not be root

# Wizard will request sudo when needed
```

### Build Issues

**1. Package conflicts:**
```bash
# Check for conflicting packages
nix-env -qa | grep conflicting-package

# Remove conflicts before building
nix-env -e conflicting-package
```

**2. Insufficient disk space:**
```bash
# Check available space
df -h /nix

# Clean up before building
nix-collect-garbage -d
```

**3. Network timeouts:**
```bash
# Use binary cache
nix-channel --add https://cache.nixos.org/
nix-channel --update

# Build with more retries
nixos-rebuild switch --max-jobs 1 --option max-retries 3
```

## 📋 Best Practices

### Before Running
1. **Backup existing configuration** if upgrading
2. **Ensure stable network connection** for downloads
3. **Have sufficient disk space** (10GB+ recommended)
4. **Know your hardware specs** for optimal configuration

### During Setup
1. **Read each step carefully** - choices affect final system
2. **Choose appropriate security level** for your environment  
3. **Consider future needs** when selecting features
4. **Test network/storage config** if uncertain

### After Completion  
1. **Review generated configuration** before building
2. **Test critical functionality** after installation
3. **Document any custom changes** for future reference
4. **Setup backups** of important data

## 🎯 Tips & Tricks

1. **Save templates** for different machine types
2. **Use dry-run mode** to preview changes
3. **Keep wizard output** for troubleshooting
4. **Review logs** if builds fail
5. **Start minimal** and add features incrementally
6. **Test in VM** before physical installation
7. **Have recovery media** ready for emergencies

## 📚 Further Reading

- [NixOS Configuration Guide](https://nixos.org/manual/nixos/stable/index.html#sec-configuration-syntax)
- [Hardware Configuration](https://nixos.wiki/wiki/Configuration_Collection)
- [Performance Tuning](https://nixos.wiki/wiki/Performance)
- [Security Hardening](https://nixos.wiki/wiki/Security)