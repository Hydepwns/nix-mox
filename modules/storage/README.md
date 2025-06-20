# Storage Modules

This directory contains storage-related modules and configurations organized by functionality.

## Structure

The storage modules are organized into fragments for better maintainability:

- `fragments/base.nix`: Common storage configuration options and validation
- `fragments/zfs.nix`: ZFS-specific configuration and auto-snapshot functionality
- `fragments/backup.nix`: General storage backup functionality
- `fragments/monitoring.nix`: Storage monitoring and health checks
- `storage.nix`: Main storage module that imports all fragments
- `zfs/`: Legacy ZFS module (for backward compatibility)

## Features

- **ZFS Management**: Automated snapshots, health monitoring, and pool management
- **Backup Solutions**: Configurable backup targets with compression and retention
- **Health Monitoring**: SMART disk checks, temperature monitoring, and space usage alerts
- **Prometheus Integration**: Built-in metrics collection for storage systems
- **Error Handling**: Comprehensive error handling and logging

## Usage

### Basic Configuration

```nix
{
  services.nix-mox.storage = {
    enable = true;
    enableMonitoring = true;
    enableLogging = true;
  };
}
```

### ZFS Auto-Snapshots

```nix
{
  services.nix-mox.zfs-auto-snapshot = {
    enable = true;
    pools = {
      "rpool" = {
        frequency = "hourly";
        retention_days = 14;
        compression = true;
        recursive = true;
      };
      "rpool/data" = {
        frequency = "daily";
        retention_days = 30;
        compression = true;
        recursive = false;
      };
    };
  };
}
```

### Storage Backups

```nix
{
  services.nix-mox.storage-backup = {
    enable = true;
    targets = {
      "home-backup" = {
        source = "/home";
        destination = "/backup/home";
        frequency = "daily";
        retention_days = 30;
        compression = true;
        exclude = [ "*.tmp" "*.log" ];
      };
    };
  };
}
```

### Storage Monitoring

```nix
{
  services.nix-mox.storage-monitoring = {
    enable = true;
    disks = {
      "sda" = {
        device = "/dev/sda";
        check_smart = true;
        check_temperature = true;
        max_temperature = 45;
      };
    };
    pools = {
      "rpool" = {
        name = "rpool";
        check_health = true;
        check_space = true;
        space_threshold = 80;
      };
    };
  };
}
```

## Configuration Options

### Base Storage Options

- `enable`: Enable storage management modules
- `defaultBackupDir`: Default directory for storage backups
- `enableMonitoring`: Enable storage monitoring and health checks
- `enableLogging`: Enable detailed storage operation logging

### ZFS Options

- `enable`: Enable declarative ZFS auto-snapshots
- `pools`: Configuration for ZFS pools/datasets to snapshot
  - `frequency`: Systemd calendar expression for snapshot frequency
  - `retention_days`: Number of days to retain snapshots
  - `compression`: Enable compression for snapshots
  - `recursive`: Create recursive snapshots of child datasets

### Backup Options

- `enable`: Enable storage backup functionality
- `targets`: Configuration for storage backup targets
  - `source`: Source path to backup
  - `destination`: Destination path for backup
  - `frequency`: Systemd calendar expression for backup frequency
  - `retention_days`: Number of days to retain backups
  - `compression`: Enable compression for backups
  - `exclude`: Patterns to exclude from backup

### Monitoring Options

- `enable`: Enable storage monitoring and health checks
- `disks`: Configuration for disk monitoring
  - `device`: Device path (e.g., /dev/sda)
  - `check_smart`: Enable SMART health checks
  - `check_temperature`: Enable temperature monitoring
  - `max_temperature`: Maximum temperature threshold in Celsius
- `pools`: Configuration for storage pool monitoring
  - `name`: Pool name
  - `check_health`: Enable pool health checks
  - `check_space`: Enable space usage monitoring
  - `space_threshold`: Space usage threshold percentage

## Fragment System

The storage modules use a fragment-based architecture for better maintainability:

- **Modular Design**: Each aspect (base, zfs, backup, monitoring) is in its own fragment
- **Conditional Loading**: Fragments are only loaded when relevant options are enabled
- **Easy Extension**: New storage types or features can be added as new fragments
- **Clear Separation**: Configuration, validation, and implementation are clearly separated

## Health Checks

The storage modules include comprehensive health checks:

1. **Disk Health**: SMART status checks and temperature monitoring
2. **Pool Health**: ZFS pool status and space usage monitoring
3. **Backup Validation**: Source existence and destination availability checks
4. **Service Status**: Systemd service and timer validation

## Monitoring

When monitoring is enabled, the modules automatically configure:

- Prometheus exporters for storage metrics
- SMART disk health monitoring
- ZFS pool status monitoring
- Temperature and space usage alerts

## Examples

### Complete Storage Setup

```nix
{
  services.nix-mox.storage = {
    enable = true;
    enableMonitoring = true;
    enableLogging = true;
  };

  services.nix-mox.zfs-auto-snapshot = {
    enable = true;
    pools = {
      "rpool" = {
        frequency = "hourly";
        retention_days = 14;
        compression = true;
        recursive = true;
      };
    };
  };

  services.nix-mox.storage-backup = {
    enable = true;
    targets = {
      "home-backup" = {
        source = "/home";
        destination = "/backup/home";
        frequency = "daily";
        retention_days = 30;
        compression = true;
      };
    };
  };

  services.nix-mox.storage-monitoring = {
    enable = true;
    disks = {
      "sda" = {
        device = "/dev/sda";
        check_smart = true;
        check_temperature = true;
        max_temperature = 45;
      };
    };
    pools = {
      "rpool" = {
        name = "rpool";
        check_health = true;
        check_space = true;
        space_threshold = 80;
      };
    };
  };
}
```

## Troubleshooting

### Common Issues

1. **ZFS pool not found**: Ensure the pool name is correct and the pool exists
2. **Device not found**: Verify the device path exists and is accessible
3. **Permission denied**: Ensure services run with appropriate permissions
4. **Backup failures**: Check source and destination paths and permissions

### Health Check Failures

The modules include detailed error messages for:
- Device not found
- SMART health check failures
- Temperature threshold exceeded
- Pool health issues
- Space usage warnings
