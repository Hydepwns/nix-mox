# Windows Templates Migration Guide

This guide explains how to migrate from the old monolithic Windows templates to the new fragment system.

## Quick Migration

### From Old Gaming Template to New Fragment System

**Old way (monolithic):**

```powershell
nu install-steam-rust.nu
```

**New way (fragment system):**

```powershell
# Basic gaming setup
nu fragments/base.nu

# Or use the gaming example
nu examples/gaming-pc.nu
```

## Migration Steps

### 1. Update Your Scripts

Replace direct calls to monolithic scripts with fragment-based configurations:

```nu
# Old: Direct script execution
source install-steam-rust.nu

# New: Fragment-based configuration
source fragments/base.nu
```

### 2. Update Environment Variables

The new system uses environment variables for configuration:

```powershell
# Set configuration via environment variables
$env.HOSTNAME = "my-gaming-pc"
$env.FEATURES = "gaming,performance"
$env.STEAM_PATH = "D:\Games\Steam"
$env.GAMES = "rust,cs2"

# Run the configuration
nu fragments/base.nu
```

### 3. Create Custom Configurations

Instead of modifying monolithic scripts, create custom configuration files:

```nu
# examples/my-custom-config.nu
$env.HOSTNAME = "my-pc"
$env.FEATURES = "gaming,development,multimedia"

source ../fragments/base.nu

# Add custom logic here
def custom-setup [] {
    print "Custom setup completed"
}

custom-setup
```

## Backward Compatibility

### Legacy Support

The old monolithic scripts are still supported for backward compatibility:

- `install-steam-rust.nu` - Still works as before
- `run-steam-rust.bat` - Still works as before
- `get-config.ps1` - Still works as before

### Gradual Migration

You can migrate gradually:

1. **Start with new projects**: Use fragments for new configurations
2. **Migrate existing projects**: Convert one template at a time
3. **Test thoroughly**: Ensure all functionality works after migration

## Migration Examples

### Gaming Template Migration

**Before (monolithic):**

```powershell
# Run the old gaming template
nu windows-gaming-template/install-steam-rust.nu
```

**After (fragment system):**

```powershell
# Option 1: Use base fragment with gaming features
$env.FEATURES = "gaming"
nu fragments/base.nu

# Option 2: Use gaming example
nu examples/gaming-pc.nu

# Option 3: Create custom gaming config
nu examples/my-gaming-setup.nu
```

### Custom Configuration Migration

**Before (modifying monolithic script):**

```nu
# Had to modify install-steam-rust.nu directly
let config = {
    steam: {
        installPath: "D:\\Games\\Steam"
    }
}
```

**After (fragment system):**

```nu
# Create custom configuration file
$env.STEAM_PATH = "D:\\Games\\Steam"
$env.FEATURES = "gaming,performance"

source fragments/base.nu
```

## Advanced Migration

### Complex Configurations

For complex configurations, create multiple fragment combinations:

```nu
# examples/enterprise-workstation.nu
$env.HOSTNAME = "enterprise-ws"
$env.FEATURES = "development,productivity,virtualization"
$env.SECURITY_LEVEL = "high"
$env.PERFORMANCE_PROFILE = "balanced"

source ../fragments/base.nu

# Add enterprise-specific logic
def setup-enterprise-tools [] {
    print "Setting up enterprise tools..."
}

setup-enterprise-tools
```

### Environment-Specific Configurations

```nu
# examples/production.nu
$env.ENVIRONMENT = "production"
$env.FEATURES = "development,productivity"
$env.SECURITY_LEVEL = "high"

source ../fragments/base.nu
```

## Troubleshooting Migration

### Common Issues

1. **Missing fragments**: Ensure all required fragments exist
2. **Environment variables**: Check that all required env vars are set
3. **Path issues**: Verify fragment paths are correct

### Debug Mode

Enable debug mode to see detailed information:

```powershell
$env.CI = "true"  # Enables debug logging
nu fragments/base.nu
```

### Dry Run Mode

Test configurations without making changes:

```powershell
$env.DRY_RUN = "true"
nu fragments/base.nu
```

## Migration Checklist

- [ ] Identify existing monolithic templates
- [ ] Create new fragment-based configurations
- [ ] Test new configurations thoroughly
- [ ] Update documentation
- [ ] Train team on new system
- [ ] Remove old templates (optional)

## Getting Help

If you encounter issues during migration:

1. Check the troubleshooting section
2. Review the fragment documentation
3. Test with dry-run mode
4. Enable debug logging
5. Create a minimal reproduction case
