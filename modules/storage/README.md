# Storage Modules

This directory contains storage-related modules and configurations organized by functionality.

## Structure

The storage modules are organized into fragments for better maintainability:

- `fragments/base.nix`: Common storage configuration options and validation
- `fragments/zfs.nix`: ZFS-specific configuration and auto-snapshot functionality
- `fragments/backup.nix`: General storage backup functionality
- `fragments/monitoring.nix`: Comprehensive storage monitoring with Prometheus/Grafana integration
- `storage.nix`: Main storage module that imports all fragments
- `templates/zfs-ssd-caching/`: ZFS SSD caching template with fragment-based architecture

## Features

- **ZFS Management**: Automated snapshots, health monitoring, and pool management
- **Backup Solutions**: Configurable backup targets with compression and retention
- **Health Monitoring**: SMART disk checks, temperature monitoring, and space usage alerts
- **Prometheus Integration**: Built-in metrics collection for storage systems with Grafana support
- **Error Handling**: Comprehensive error handling and logging
- **Template System**: Pre-configured templates for common storage scenarios

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
    enablePrometheus = true;
    enableGrafana = true;
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

### Using Templates

```nix
{
  # Import the ZFS SSD caching template
  imports = [ modules.storage.templates.zfs-ssd-caching ];
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
- `enablePrometheus`: Enable Prometheus metrics collection
- `enableGrafana`: Enable Grafana dashboard provisioning
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
- **Template Integration**: Templates can import specific fragments as needed

## Health Checks

The storage modules include comprehensive health checks:

1. **Disk Health**: SMART status checks and temperature monitoring
2. **Pool Health**: ZFS pool status and space usage monitoring
3. **Backup Validation**: Source existence and destination availability checks
4. **Service Status**: Systemd service and timer validation

## Monitoring

When monitoring is enabled, the modules automatically configure:

- Prometheus exporters for storage metrics (including ZFS and SMART data)
- SMART disk health monitoring
- ZFS pool status monitoring
- Temperature and space usage alerts
- Grafana dashboard provisioning (optional)

## Templates

### ZFS SSD Caching Template

The `zfs-ssd-caching` template provides automated configuration for ZFS SSD caching:

- **Automatic Detection**: Automatically detects NVMe SSDs
- **Flexible Configuration**: Supports both L2ARC and Special VDEVs
- **Health Checks**: Comprehensive device and pool health validation
- **Error Handling**: Robust error handling with retry logic
- **Monitoring Integration**: Works with the main storage monitoring system

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

  services.nix-mox.storage-monitoring = {
    enable = true;
    enablePrometheus = true;
    enableGrafana = true;
  };
}
```

### Template-Based Setup

```nix
{
  # Import storage modules
  imports = [ modules.storage.storage ];

  # Use ZFS SSD caching template
  imports = [ modules.storage.templates.zfs-ssd-caching ];

  # Configure monitoring
  services.nix-mox.storage-monitoring = {
    enable = true;
    enablePrometheus = true;
  };
}
```

## Recent Changes

### Cleanup (Latest)

- **Consolidated Monitoring**: Merged template-specific monitoring into the main monitoring fragment
- **Removed Legacy Modules**: Eliminated redundant ZFS modules in favor of the fragment-based approach
- **Standardized Imports**: All modules now use consistent import patterns
- **Enhanced Documentation**: Updated README to reflect the new structure and capabilities
- **Template Simplification**: Templates now focus on their specific functionality without duplicating common features
