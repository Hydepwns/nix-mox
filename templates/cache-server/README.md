# Cache Server Template

This template provides a flexible and powerful caching solution with support for both Redis and Memcached. It includes features for high availability, monitoring, backups, and custom configuration.

## Features

- Support for multiple cache server types:
  - Redis
  - Memcached
- Health checks and monitoring
- Automated backups
- Memory management
- Authentication support
- Prometheus metrics integration
- Custom configuration options
- Error handling and logging

## Usage

### Basic Configuration

```nix
services.nix-mox.cache-server = {
  enable = true;
  cacheType = "redis";  # or "memcached"
  bindAddress = "127.0.0.1";
  maxMemory = 1024;  # MB
  maxConnections = 1024;
  password = "secure_password";
  enableMonitoring = true;
  enableBackup = true;
  backupDir = "/var/lib/cache-server/backups";
  backupRetention = 7;  # days
};
```

### Advanced Configuration

```nix
services.nix-mox.cache-server = {
  enable = true;
  cacheType = "redis";
  bindAddress = "0.0.0.0";
  maxMemory = 4096;
  maxConnections = 2048;
  evictionPolicy = "allkeys-lru";
  persistence = true;
  password = "secure_password";
  enableMonitoring = true;
  enableBackup = true;
  backupDir = "/var/lib/cache-server/backups";
  backupRetention = 30;
  customConfig = {
    tcpKeepAlive = 300;
    timeout = 0;
    databases = 16;
  };
};
```

## Configuration Options

### Cache Server Type

- `cacheType`: Type of cache server to use
  - Options: "redis" or "memcached"
  - Default: "redis"

### Basic Settings

- `bindAddress`: Address to bind the cache server to
  - Default: "127.0.0.1"
- `maxMemory`: Maximum memory usage in MB
  - Default: 1024
- `maxConnections`: Maximum number of connections
  - Default: 1024

### Redis-specific Settings

- `evictionPolicy`: Memory eviction policy
  - Options: "noeviction", "allkeys-lru", "volatile-lru", "allkeys-random", "volatile-random", "volatile-ttl"
  - Default: "noeviction"
- `persistence`: Enable persistence
  - Default: true

### Security

- `password`: Password for authentication
  - Optional
  - Default: null

### Monitoring

- `enableMonitoring`: Enable Prometheus monitoring
  - Default: true

### Backup

- `enableBackup`: Enable automated backups
  - Default: true
- `backupDir`: Directory for backups
  - Default: "/var/lib/cache-server/backups"
- `backupRetention`: Number of days to retain backups
  - Default: 7

### Custom Configuration

- `customConfig`: Additional cache server configuration
  - Type: attribute set
  - Optional

## Health Checks

The template performs the following health checks:

1. Cache server service status
2. Port availability
3. Metrics availability (if monitoring is enabled)
4. Cache server response

## Monitoring

### Prometheus Integration

- Redis exporter: Port 9121
- Memcached exporter: Port 9150
- Metrics available:
  - Memory usage
  - Connection counts
  - Command statistics
  - Hit/miss ratios
  - Eviction statistics
  - Replication status (Redis)

## Backup

### Redis Backup

- Creates RDB snapshots
- Daily automated backups
- Configurable retention period
- Backup rotation

### Memcached Backup

- Exports server statistics
- Daily automated backups
- Configurable retention period
- Backup rotation

## Error Handling

The template uses the standardized error handling module for:

- Configuration validation
- Service status checks
- Health check failures
- Monitoring setup
- Backup operations
- Logging

## Examples

### Basic Redis Setup

```nix
services.nix-mox.cache-server = {
  enable = true;
  cacheType = "redis";
  bindAddress = "127.0.0.1";
  maxMemory = 1024;
  password = "secure_password";
  enableMonitoring = true;
  enableBackup = true;
};
```

### Memcached with Custom Settings

```nix
services.nix-mox.cache-server = {
  enable = true;
  cacheType = "memcached";
  bindAddress = "0.0.0.0";
  maxMemory = 2048;
  maxConnections = 2048;
  password = "secure_password";
  enableMonitoring = true;
  enableBackup = true;
  backupRetention = 14;
  customConfig = {
    threadCount = 4;
    maxItemSize = "1m";
  };
};
```

## Troubleshooting

### Common Issues

1. Service not starting
   - Check systemd logs: `journalctl -u nix-mox-cache-server-{redis,memcached}`
   - Verify configuration syntax
   - Check port availability

2. Memory issues
   - Monitor memory usage
   - Adjust maxMemory setting
   - Check eviction policy (Redis)

3. Connection issues
   - Verify bindAddress setting
   - Check firewall rules
   - Monitor connection count

4. Backup failures
   - Check backup directory permissions
   - Verify disk space
   - Check backup script logs

### Logs

- Systemd logs: `journalctl -u nix-mox-cache-server-{redis,memcached}`
- Redis logs: `/var/log/redis/redis.log`
- Memcached logs: `/var/log/memcached/memcached.log`
- Backup logs: `journalctl -u nix-mox-cache-server-backup-{redis,memcached}`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This template is licensed under the MIT License. 