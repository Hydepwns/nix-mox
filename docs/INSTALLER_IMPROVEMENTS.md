# Interactive Installer Improvements

> Enhanced setup experience for accessing your favorite parts of nix-mox configuration.

## 🎯 **Overview**

The nix-mox interactive installer has been significantly enhanced to provide better access to your favorite configuration components. Instead of being limited to preset templates, you can now:

- **Browse** available components before making decisions
- **Select** specific components you want
- **Preview** what will be installed
- **Mix and match** components from different categories
- **Use quick presets** for common configurations

## 🚀 **New Setup Options**

### **1. Quick Favorites Setup** ⚡
Fast setup with popular preset configurations that combine the most commonly used components.

**Usage:**
```bash
# Browse available presets
nu scripts/setup/quick-favorites.nu

# Apply a specific preset
nu scripts/setup/quick-favorites.nu dev-gaming
nu scripts/setup/quick-favorites.nu productivity
```

**Available Presets:**
- `dev-gaming` - Developer Gaming Rig (development + gaming)
- `productivity` - Productivity Workstation (office + communication)
- `gaming-only` - Pure Gaming Machine (all gaming platforms)
- `dev-server` - Development Server (server + development)
- `minimal-dev` - Minimal Development (lightweight dev tools)
- `media-center` - Media Center (entertainment + media)

### **2. Enhanced Setup** 🎛️
Granular component selection allowing you to pick exactly what you want.

**Usage:**
```bash
# Interactive component selection
nu scripts/setup/enhanced-setup.nu
```

**Component Categories:**
- **Development Tools**: IDEs, compilers, debuggers, build tools
- **Gaming & Entertainment**: Gaming platforms, performance tools, media players
- **Productivity & Communication**: Office apps, messaging, email clients
- **System & Security**: Monitoring, security, networking, utilities

### **3. Component Browser** 🔍
Explore and preview available components before making selections.

**Usage:**
```bash
# Browse all components
nu scripts/setup/component-browser.nu

# Explore specific categories
nu scripts/setup/component-browser.nu --category development
nu scripts/setup/component-browser.nu --category gaming

# Get detailed component information
nu scripts/setup/component-browser.nu --category gaming --component platforms
```

## 📦 **Available Components**

### **Development Tools** 💻
- **Code Editors & IDEs**: VSCode, Vim, Neovim, JetBrains IDEs
- **Programming Languages**: Rust, Python, Node.js, Go, Java, C/C++
- **Development Tools**: Git, Docker, CMake, Ninja, GDB, LLDB

### **Gaming & Entertainment** 🎮
- **Gaming Platforms**: Steam, Lutris, Heroic
- **Performance Tools**: Gamemode, MangoHud, monitoring tools
- **Media & Entertainment**: VLC, mpv, Spotify, OBS Studio
- **Gaming Communication**: Discord, Teamspeak, Mumble

### **Productivity & Communication** 📊
- **Communication**: Discord, Signal, Telegram, Thunderbird
- **Office & Productivity**: LibreOffice, Obsidian, Joplin
- **Utilities**: File managers, system monitors, backup tools

### **System & Security** 🛡️
- **System Monitoring**: htop, btop, neofetch, inxi
- **Security Tools**: UFW, GPG, password managers
- **Networking**: Tailscale, OpenVPN, Wireshark

## 🔧 **How It Works**

### **Component Selection Process**
1. **Browse** - Use component browser to explore available options
2. **Select** - Choose specific components you want
3. **Preview** - See what packages and services will be installed
4. **Confirm** - Review and confirm your selection
5. **Generate** - Create custom configuration files

### **Configuration Generation**
The installer automatically:
- Generates appropriate package lists based on your selections
- Configures necessary services (Docker, SSH, Steam, etc.)
- Creates personal and system configuration files
- Sets up environment variables
- Provides next steps and usage instructions

### **Package Management**
- **Automatic deduplication** - No duplicate packages
- **Dependency resolution** - Required dependencies are included
- **Size optimization** - Only installs what you need
- **Service configuration** - Properly configures related services

## 🎯 **Use Cases**

### **For Developers**
```bash
# Quick development setup
nu scripts/setup/quick-favorites.nu dev-gaming

# Or granular selection
nu scripts/setup/enhanced-setup.nu
# Select: Development Tools > Code Editors, Languages, Tools
```

### **For Gamers**
```bash
# Pure gaming setup
nu scripts/setup/quick-favorites.nu gaming-only

# Or browse gaming components
nu scripts/setup/component-browser.nu --category gaming
```

### **For Productivity**
```bash
# Productivity workstation
nu scripts/setup/quick-favorites.nu productivity

# Or select specific productivity tools
nu scripts/setup/enhanced-setup.nu
# Select: Productivity > Communication, Office, Utilities
```

### **For Servers**
```bash
# Development server
nu scripts/setup/quick-favorites.nu dev-server

# Or minimal development
nu scripts/setup/quick-favorites.nu minimal-dev
```

## 🔄 **Migration from Old Installer**

If you're using the old template-based installer:

### **Before (Old Way)**
```bash
# Limited to preset templates
cp config/templates/gaming.nix config/nixos/configuration.nix
# No customization, all-or-nothing approach
```

### **After (New Way)**
```bash
# Granular component selection
nu scripts/setup/enhanced-setup.nu
# Choose exactly what you want

# Or quick preset with customization
nu scripts/setup/quick-favorites.nu dev-gaming
# Then manually add/remove components as needed
```

## 📋 **Configuration Files Generated**

The new installers create:

### **Personal Configuration** (`config/personal/user.nix`)
- User account settings
- System configuration (hostname, timezone)
- Git configuration
- Basic user preferences

### **Main Configuration** (`config/nixos/configuration.nix`)
- Selected packages based on your choices
- Configured services (Docker, SSH, Steam, etc.)
- System settings and optimizations
- Security and networking configuration

### **Environment File** (`.env`)
- User information
- Selected components
- Preset information (if using quick favorites)

## 🎉 **Benefits**

### **For New Users**
- **Easier onboarding** - Clear options and descriptions
- **No overwhelming choices** - Start with presets, customize later
- **Better understanding** - Component browser explains what each part does
- **Safer setup** - Preview before applying

### **For Experienced Users**
- **Granular control** - Pick exactly what you want
- **Mix and match** - Combine components from different categories
- **Custom configurations** - Create your perfect setup
- **Efficient setup** - No unnecessary packages

### **For All Users**
- **Better organization** - Components are logically grouped
- **Comprehensive coverage** - All major use cases covered
- **Future-proof** - Easy to add new components
- **Maintainable** - Clear separation of concerns

## 🚀 **Getting Started**

1. **Explore components**:
   ```bash
   nu scripts/setup/component-browser.nu
   ```

2. **Try a quick preset**:
   ```bash
   nu scripts/setup/quick-favorites.nu dev-gaming
   ```

3. **Or go granular**:
   ```bash
   nu scripts/setup/enhanced-setup.nu
   ```

4. **Build and enjoy**:
   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

## 🔮 **Future Enhancements**

Planned improvements:
- **Component dependencies** - Automatic dependency resolution
- **Custom component creation** - User-defined components
- **Configuration sharing** - Share component selections
- **Advanced preview** - Show system impact and resource usage
- **Integration with existing configs** - Merge with current setup

## 📚 **Related Documentation**

- [Quick Start Guide](QUICK_START.md) - Getting started with nix-mox
- [Templates Guide](TEMPLATES.md) - Traditional template-based setup
- [Configuration Guide](CONFIGURATION.md) - Advanced configuration options
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and solutions 