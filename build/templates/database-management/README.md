# Database Management Template

This template provides comprehensive database management capabilities for PostgreSQL and MySQL databases, including health checks, automated backups, and monitoring.

## Features

- Support for PostgreSQL and MySQL databases
- Automated health checks
- Configurable backup schedules
- Prometheus monitoring integration
- Custom configuration options
- Error handling and logging

## Usage

### Basic Configuration

```nix
services.nix-mox.database-management = {
  enable = true;
  dbType = "postgresql";  # or "mysql"
};
```

### Advanced Configuration

```nix
services.nix-mox.database-management = {
  enable = true;
  dbType = "postgresql";
  enableBackups = true;
  backupInterval = "daily";  # or "weekly", "monthly"
  enableMonitoring = true;
  customConfig = {
    # Custom database configuration
    max_connections = 100;
    shared_buffers = "1GB";
  };
};
```

## Configuration Options

### `enable`

Enable or disable the database management template.

### `dbType`

Type of database to manage. Available options:

- `postgresql`: PostgreSQL database
- `mysql`: MySQL database

### `enableBackups`

Enable or disable automatic backups.

### `backupInterval`

Backup schedule. Available options:

- `daily`: Daily backups
- `weekly`: Weekly backups
- `monthly`: Monthly backups

### `enableMonitoring`

Enable or disable Prometheus monitoring.

### `customConfig`

Custom database configuration options. See the respective database documentation for available options.

## Health Checks

The template performs the following health checks:

1. Database service status
2. Database connection
3. Disk space availability

## Backups

Backups are stored in `/var/backups/<database-type>/` with timestamps in the filename.

## Monitoring

The template integrates with Prometheus for monitoring:

- PostgreSQL: Exporter runs on port 9187
- MySQL: Exporter runs on port 9104

## Error Handling

The template uses the standardized error handling module for consistent error management and logging.

## Examples

### PostgreSQL with Daily Backups

```nix
services.nix-mox.database-management = {
  enable = true;
  dbType = "postgresql";
  enableBackups = true;
  backupInterval = "daily";
  enableMonitoring = true;
};
```

### MySQL with Weekly Backups

```nix
services.nix-mox.database-management = {
  enable = true;
  dbType = "mysql";
  enableBackups = true;
  backupInterval = "weekly";
  enableMonitoring = true;
};
```

### Custom PostgreSQL Configuration

```nix
services.nix-mox.database-management = {
  enable = true;
  dbType = "postgresql";
  customConfig = {
    max_connections = 200;
    shared_buffers = "2GB";
    work_mem = "64MB";
    maintenance_work_mem = "256MB";
  };
};
```

## Troubleshooting

### Common Issues

1. **Database Service Not Running**
   - Check systemd service status: `systemctl status postgresql` or `systemctl status mysql`
   - Check logs: `journalctl -u postgresql` or `journalctl -u mysql`

2. **Backup Failures**
   - Verify disk space: `df -h /var/backups`
   - Check backup directory permissions
   - Review backup logs

3. **Monitoring Issues**
   - Verify Prometheus exporter is running
   - Check exporter ports are accessible
   - Review Prometheus configuration

### Logs

- Database logs: `journalctl -u postgresql` or `journalctl -u mysql`
- Template logs: `journalctl -u nix-mox-database-postgresql` or `journalctl -u nix-mox-database-mysql`
- Backup logs: `journalctl -u nix-mox-database-postgresql-backup` or `journalctl -u nix-mox-database-mysql-backup`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This template is licensed under the MIT License.
