# Windows Fragment System - Quick Start

Get started with the new Windows fragment system in minutes!

## Quick Start

### 1. Basic Windows Setup

```powershell
# Set basic configuration
$env.HOSTNAME = "my-pc"
$env.FEATURES = "base"

# Run the base fragment
nu fragments/base.nu
```

### 2. Gaming PC Setup

```powershell
# Set gaming configuration
$env.HOSTNAME = "gaming-pc"
$env.FEATURES = "gaming,performance"
$env.STEAM_PATH = "D:\Games\Steam"
$env.GAMES = "rust,cs2"

# Run the base fragment
nu fragments/base.nu
```

### 3. Development Workstation

```powershell
# Set development configuration
$env.HOSTNAME = "dev-ws"
$env.FEATURES = "development,productivity"
$env.SECURITY_LEVEL = "high"

# Run the base fragment
nu fragments/base.nu
```

## Available Features

| Feature | Description | Environment Variable |
|---------|-------------|-------------------|
| **base** | Essential Windows setup | Always included |
| **gaming** | Steam, Epic, game optimizations | `$env.FEATURES = "gaming"` |
| **development** | VS Code, Git, Docker, languages | `$env.FEATURES = "development"` |
| **multimedia** | Media players, editing software | `$env.FEATURES = "multimedia"` |
| **productivity** | Office suites, collaboration tools | `$env.FEATURES = "productivity"` |
| **virtualization** | Hyper-V, VirtualBox, WSL | `$env.FEATURES = "virtualization"` |
| **performance** | Performance optimizations | `$env.FEATURES = "performance"` |

## Configuration Options

### Environment Variables

```powershell
# System settings
$env.HOSTNAME = "my-pc"                    # Computer hostname
$env.USER = "admin"                        # Admin username
$env.PASSWORD = "secure-password"          # Admin password

# Installation paths
$env.INSTALL_PATH = "C:\Program Files"     # Main installation directory
$env.GAMES_PATH = "D:\Games"               # Games installation directory
$env.STEAM_PATH = "D:\Games\Steam"         # Steam installation path

# Features to enable
$env.FEATURES = "gaming,development"       # Comma-separated feature list

# Security and performance
$env.SECURITY_LEVEL = "medium"             # low, medium, high
$env.PERFORMANCE_PROFILE = "balanced"      # power-saver, balanced, high-performance

# Games to install
$env.GAMES = "rust,cs2,minecraft"          # Comma-separated game list

# Debug options
$env.CI = "true"                          # Enable debug logging
$env.DRY_RUN = "true"                     # Test without making changes
```

### Multiple Features

```powershell
# Combine multiple features
$env.FEATURES = "gaming,development,multimedia,performance"
```

## Common Use Cases

### Gaming PC
```powershell
$env.HOSTNAME = "gaming-pc"
$env.FEATURES = "gaming,performance"
$env.STEAM_PATH = "D:\Games\Steam"
$env.GAMES = "rust,cs2,minecraft"
$env.PERFORMANCE_PROFILE = "high-performance"
nu fragments/base.nu
```

### Development Workstation
```powershell
$env.HOSTNAME = "dev-ws"
$env.FEATURES = "development,productivity,virtualization"
$env.SECURITY_LEVEL = "high"
$env.PERFORMANCE_PROFILE = "balanced"
nu fragments/base.nu
```

### Multimedia Workstation
```powershell
$env.HOSTNAME = "multimedia-ws"
$env.FEATURES = "multimedia,performance"
$env.INSTALL_PATH = "D:\Programs"
$env.PERFORMANCE_PROFILE = "high-performance"
nu fragments/base.nu
```

### Enterprise Workstation
```powershell
$env.HOSTNAME = "enterprise-ws"
$env.FEATURES = "development,productivity,virtualization"
$env.SECURITY_LEVEL = "high"
$env.PERFORMANCE_PROFILE = "balanced"
nu fragments/base.nu
```

## Testing and Debugging

### Dry Run Mode
Test your configuration without making changes:

```powershell
$env.DRY_RUN = "true"
$env.FEATURES = "gaming"
nu fragments/base.nu
```

### Debug Mode
Enable detailed logging:

```powershell
$env.CI = "true"
$env.FEATURES = "gaming"
nu fragments/base.nu
```

### Validate Configuration
Check your configuration before running:

```powershell
# Test configuration syntax
nu --check fragments/base.nu
```

## 📁 File Structure

```
modules/templates/windows/
├── fragments/                    # Fragment modules
│   ├── base.nu                  # Main entry point
│   ├── prerequisites.nu         # System requirements
│   ├── networking.nu            # Network configuration
│   ├── security.nu              # Security settings
│   ├── performance.nu           # Performance optimization
│   ├── maintenance.nu           # System maintenance
│   ├── gaming.nu                # Gaming platforms
│   ├── development.nu           # Development tools
│   ├── multimedia.nu            # Media software
│   ├── productivity.nu          # Office tools
│   └── virtualization.nu        # VM support
├── examples/                    # Example configurations
│   ├── gaming-pc.nu            # Gaming PC example
│   ├── development-workstation.nu # Dev workstation example
│   └── multimedia-workstation.nu # Multimedia example
├── windows-gaming-template/     # Legacy template (backward compatible)
├── README-fragments.md         # Comprehensive documentation
├── MIGRATION.md                # Migration guide
├── FRAGMENT-SYSTEM.md          # System overview
└── QUICK-START.md              # This file
```

## Troubleshooting

### Common Issues

1. **"Script must be run as Administrator"**
   - Run PowerShell as Administrator

2. **"Insufficient disk space"**
   - Free up at least 50GB on C: drive

3. **"Windows 10 or later is required"**
   - Upgrade to Windows 10 or later

4. **"No internet connection available"**
   - Check your internet connection

### Getting Help

1. **Check logs** - Look for error messages in the output
2. **Enable debug mode** - Set `$env.CI = "true"`
3. **Use dry run** - Set `$env.DRY_RUN = "true"`
4. **Review documentation** - Check `README-fragments.md`
5. **Check examples** - Look at `examples/` directory

## Migration from Old System

If you're using the old monolithic templates:

```powershell
# Old way
nu windows-gaming-template/install-steam-rust.nu

# New way
$env.FEATURES = "gaming"
$env.GAMES = "rust"
nu fragments/base.nu
```

See `MIGRATION.md` for detailed migration instructions.

## Next Steps

1. **Try the examples** - Run the example configurations
2. **Create custom configs** - Build your own configurations
3. **Read the docs** - Check `README-fragments.md` for advanced usage
4. **Contribute** - Add new fragments or improve existing ones

Happy configuring! 
