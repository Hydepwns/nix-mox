# Storage Safety Guide

> Critical guide for preventing boot failures due to storage configuration issues

## Overview

Storage configuration issues are a common cause of boot failures in NixOS systems. This guide provides comprehensive information on preventing, detecting, and resolving these issues.

## Root Cause: PartUUID Instability

### What Causes PartUUID Changes?

PartUUIDs can change when:
- **Partition table modifications**: Resizing, repairing, or recreating partitions
- **Disk cloning/backup**: Restoring from backup can rewrite partition tables
- **Hardware changes**: Moving disks between systems or hardware upgrades
- **Firmware updates**: Disk controller or system firmware updates
- **Disk replacement**: Installing new storage devices

### Why This Causes Boot Failures

1. **Initrd dependency**: The initial ramdisk (initrd) needs to find the root partition
2. **Configuration drift**: Hardware configuration references old partuuid
3. **Boot failure**: System can't mount root filesystem, causing boot failure

## Defensive Tools

### 1. Storage Guard (`nix run .#storage-guard`)

**Purpose**: Pre-reboot validation of storage configuration

**What it checks**:
- Device resolution (can the configured device be found?)
- UUID/partuuid consistency (does config match reality?)
- Initrd modules (are required modules available?)
- Filesystem type validation

**Usage**:
```bash
# Run before every reboot
nix run .#storage-guard

# If issues detected, fix them before rebooting
```

### 2. Fix Storage Tool (`nix run .#fix-storage`)

**Purpose**: Automatic detection and correction of storage issues

**Features**:
- Detects mismatched partuuid/UUID
- Offers choice between UUID (more stable) or partuuid
- Creates backup before making changes
- Provides detailed analysis

**Usage**:
```bash
# Auto-detect and fix issues
nix run .#fix-storage

# Choose identifier type when prompted
# 1. UUID (recommended - more stable)
# 2. partuuid (can change with partition table modifications)
# 3. Skip fix
```

## Best Practices

### 1. Identifier Stability Hierarchy

**Most Stable → Least Stable**:
1. **Filesystem UUID** - Survives partition table changes
2. **PartUUID** - Stable unless partition table modified
3. **Device names** - Can change with hardware changes

### 2. Configuration Recommendations

```nix
# RECOMMENDED: Use UUID for root (most stable)
fileSystems."/" = {
  device = "/dev/disk/by-uuid/7938b5a4-ae4d-475c-acda-664f3d04f9f0";
  fsType = "ext4";
};

# ACCEPTABLE: Use partuuid for boot (EFI partuuid is stable)
fileSystems."/boot" = {
  device = "/dev/disk/by-partuuid/8021e6ba-3192-4507-b0aa-d5836e86a0b9";
  fsType = "vfat";
  options = [ "fmask=0077" "dmask=0077" ];
};

# AVOID: Device names (least stable)
fileSystems."/" = {
  device = "/dev/nvme0n1p2";  # ❌ Can change
  fsType = "ext4";
};
```

### 3. Maintenance Workflow

1. **Before any reboot**:
   ```bash
   nix run .#storage-guard
   ```

2. **If issues detected**:
   ```bash
   nix run .#fix-storage
   ```

3. **Verify fix**:
   ```bash
   nix run .#storage-guard
   ```

4. **Test configuration**:
   ```bash
   nix build .#nixosConfigurations.nixos.config.system.build.toplevel
   ```

5. **Reboot safely**:
   ```bash
   nixos-rebuild switch --flake .#nixos
   ```

## Troubleshooting

### Symptoms of Storage Configuration Problems

- System fails to boot after reboot
- Initrd can't find root partition
- "No such device" errors during boot
- Successful rebuild but boot failure
- Emergency mode or rescue shell

### Diagnostic Commands

```bash
# Check current mount points and UUIDs
findmnt -no UUID,FSTYPE,SOURCE /

# Check partuuid vs UUID
sudo blkid /dev/nvme0n1p2

# List available identifiers
ls -la /dev/disk/by-uuid/
ls -la /dev/disk/by-partuuid/

# Run storage validation
nix run .#storage-guard

# Check hardware configuration
cat /etc/nixos/hardware-configuration.nix
```

### Recovery Steps

1. **Boot into rescue mode**:
   - Use recovery media or previous generation
   - Mount the root filesystem

2. **Fix configuration**:
   ```bash
   nix run .#fix-storage
   ```

3. **Verify fix**:
   ```bash
   nix run .#storage-guard
   ```

4. **Rebuild and reboot**:
   ```bash
   nixos-rebuild switch --flake .#nixos
   ```

## Integration with Development Workflow

### Makefile Targets

```bash
# Validate storage before reboot
make storage-guard

# Auto-fix storage issues
make fix-storage
```

### CI/CD Integration

Add storage validation to your CI pipeline:

```yaml
- name: Validate storage configuration
  run: nix run .#storage-guard
```

### Pre-commit Hooks

Consider adding storage validation to pre-commit hooks for hardware configuration changes.

## Common Scenarios

### Scenario 1: Fresh Installation

1. Install NixOS
2. Generate hardware configuration
3. Run storage guard to validate
4. Reboot and test

### Scenario 2: Disk Replacement

1. Replace disk
2. Restore from backup
3. Run fix-storage to update configuration
4. Validate with storage-guard
5. Reboot

### Scenario 3: Partition Resizing

1. Resize partitions
2. Run fix-storage to update partuuid references
3. Validate with storage-guard
4. Reboot

## Advanced Topics

### Custom Storage Validation

You can extend the storage guard for custom validation:

```nushell
# Add custom checks to storage-guard.nu
def custom_storage_check [] {
  # Your custom validation logic
}
```

### Integration with Monitoring

Consider integrating storage validation with your monitoring system:

```bash
# Add to cron job
0 */6 * * * nix run .#storage-guard
```

## Support

If you encounter storage issues:

1. Check this guide first
2. Run diagnostic commands
3. Use the fix-storage tool
4. Check the troubleshooting section
5. Review system logs for additional context

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Development guidance
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - General troubleshooting
- [QUICK_START.md](QUICK_START.md) - Getting started guide 