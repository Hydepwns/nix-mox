# Windows Templates

Modern, modular Windows configuration templates using a fragment system for flexible and maintainable setups.

## 🚀 Quick Start

### Basic Windows Setup

```powershell
$env.HOSTNAME = "my-pc"
$env.FEATURES = "base"
nu fragments/base.nu
```

### Gaming PC

```powershell
$env.HOSTNAME = "gaming-pc"
$env.FEATURES = "gaming,performance"
$env.STEAM_PATH = "D:\Games\Steam"
$env.GAMES = "rust,cs2"
nu fragments/base.nu
```

### Development Workstation

```powershell
$env.HOSTNAME = "dev-ws"
$env.FEATURES = "development,productivity"
$env.SECURITY_LEVEL = "high"
nu fragments/base.nu
```

## 📋 Available Features

| Feature | Description | Environment Variable |
|---------|-------------|-------------------|
| **base** | Essential Windows setup | Always included |
| **gaming** | Steam, Epic, game optimizations | `$env.FEATURES = "gaming"` |
| **development** | VS Code, Git, Docker, languages | `$env.FEATURES = "development"` |
| **multimedia** | Media players, editing software | `$env.FEATURES = "multimedia"` |
| **productivity** | Office suites, collaboration tools | `$env.FEATURES = "productivity"` |
| **virtualization** | Hyper-V, VirtualBox, WSL | `$env.FEATURES = "virtualization"` |
| **performance** | Performance optimizations | `$env.FEATURES = "performance"` |

## ⚙️ Configuration

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

## 🎯 Configuration Examples

### Gaming PC Configuration

```powershell
$env.HOSTNAME = "gaming-pc"
$env.FEATURES = "gaming,performance"
$env.STEAM_PATH = "D:\Games\Steam"
$env.GAMES = "rust,cs2,minecraft"
$env.PERFORMANCE_PROFILE = "high-performance"
nu fragments/base.nu
```

### Development Workstation Configuration

```powershell
$env.HOSTNAME = "dev-ws"
$env.FEATURES = "development,productivity,virtualization"
$env.SECURITY_LEVEL = "high"
$env.PERFORMANCE_PROFILE = "balanced"
nu fragments/base.nu
```

### Multimedia Workstation Configuration

```powershell
$env.HOSTNAME = "multimedia-ws"
$env.FEATURES = "multimedia,performance"
$env.INSTALL_PATH = "D:\Programs"
$env.PERFORMANCE_PROFILE = "high-performance"
nu fragments/base.nu
```

### Enterprise Workstation Configuration

```powershell
$env.HOSTNAME = "enterprise-ws"
$env.FEATURES = "development,productivity,virtualization"
$env.SECURITY_LEVEL = "high"
$env.PERFORMANCE_PROFILE = "balanced"
nu fragments/base.nu
```

## 📁 Structure

```bash
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
└── docs/                        # Documentation
    ├── FRAGMENT-SYSTEM.md      # System overview
    ├── MIGRATION.md            # Migration guide
    └── QUICK-START.md          # Quick start guide
```

## 🔧 Testing and Debugging

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

## 🔄 Migration from Old System

If you're using the old monolithic templates:

```powershell
# Old way
nu windows-gaming-template/install-steam-rust.nu

# New way
$env.FEATURES = "gaming"
$env.GAMES = "rust"
nu fragments/base.nu
```

## 🆘 Troubleshooting

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
4. **Review documentation** - Check `docs/` directory
5. **Check examples** - Look at `examples/` directory

## 📚 Documentation

- **[Fragment System Overview](docs/FRAGMENT-SYSTEM.md)** - Detailed system architecture
- **[Migration Guide](docs/MIGRATION.md)** - Step-by-step migration instructions
- **[Quick Start Guide](docs/QUICK-START.md)** - Get started in minutes

## 🤝 Contributing

When adding new fragments:

1. **Keep it focused** - Each fragment should handle one concern
2. **Document it well** - Include comments and examples
3. **Test thoroughly** - Ensure it works with other fragments
4. **Follow conventions** - Use consistent naming and structure
5. **Maintain compatibility** - Don't break existing configurations

## 🔮 Features

- **Modular Architecture** - Reusable, focused fragments
- **Environment-Based Configuration** - Flexible setup via environment variables
- **Backward Compatibility** - Old templates still work
- **Testing Support** - Dry-run and debug modes
- **Extensible** - Easy to add new fragments
- **Well Documented** - Comprehensive guides and examples

---

**Happy configuring! 🎉**
