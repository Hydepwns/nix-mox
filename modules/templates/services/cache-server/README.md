# Cache Server Template

This template provides automated configuration for cache servers including Redis and Memcached. It includes comprehensive monitoring, health checks, and automated maintenance features.

## Features

- **Multiple Cache Types**: Support for Redis and Memcached
- **Health Monitoring**: Automated health checks and validation
- **Prometheus Integration**: Built-in metrics collection
- **Automated Backups**: Configurable backup schedules with retention
- **Security**: Password protection and access control
- **Performance Tuning**: Memory and connection optimization

## Structure

The template is organized into fragments for better maintainability:

- `fragments/base.nix`: Common configuration options and validation
- `fragments/redis.nix`: Redis-specific configuration and health checks
- `fragments/memcached.nix`: Memcached-specific configuration and health checks
- `fragments/monitoring.nix`: Prometheus monitoring setup
- `fragments/backup.nix`: Automated backup functionality
- `cache-server.nix`: Main template that imports all fragments

## Usage

### Basic Configuration

```nix
{
  services.nix-mox.cache-server = {
    enable = true;
    cacheType = "redis";  # or "memcached"
    bindAddress = "127.0.0.1";
    maxMemory = 1024;
    maxConnections = 1024;
  };
}
```

### Advanced Configuration

```nix
{
  services.nix-mox.cache-server = {
    enable = true;
    cacheType = "redis";
    
    # Redis-specific options
    evictionPolicy = "allkeys-lru";
    persistence = true;
    
    # Security
    password = "your-secure-password";
    
    # Monitoring
    enableMonitoring = true;
    
    # Backup
    enableBackup = true;
    backupDir = "/var/lib/cache-server/backups";
    backupRetention = 7;
  };
}
```

## Configuration Options

### Base Options

- `enable`: Enable the cache server template
- `cacheType`: Type of cache server ("redis" or "memcached")
- `bindAddress`: Address to bind the cache server to
- `maxMemory`: Maximum memory usage in MB
- `maxConnections`: Maximum number of connections
- `password`: Password for authentication (optional)
- `customConfig`: Custom cache server configuration

### Redis-Specific Options

- `evictionPolicy`: Memory eviction policy
  - `noeviction`: No eviction (default)
  - `allkeys-lru`: Least recently used
  - `volatile-lru`: Volatile keys least recently used
  - `allkeys-random`: Random eviction
  - `volatile-random`: Volatile keys random eviction
  - `volatile-ttl`: Volatile keys time to live
- `persistence`: Enable persistence (AOF)

### Monitoring Options

- `enableMonitoring`: Enable Prometheus monitoring
- Metrics are available on:
  - Redis: Port 9121
  - Memcached: Port 9150

### Backup Options

- `enableBackup`: Enable automated backups
- `backupDir`: Directory for backups
- `backupRetention`: Number of days to retain backups

## Health Checks

The template includes comprehensive health checks:

1. **Service Status**: Verifies the cache server service is running
2. **Port Availability**: Checks if the server is listening on the configured port
3. **Response Validation**: Tests actual cache server responses
4. **Monitoring Health**: Validates metrics endpoint availability (if enabled)

## Monitoring

When `enableMonitoring` is enabled, the template automatically configures:

- Prometheus exporters for the selected cache type
- Metrics collection on dedicated ports
- Health check integration

## Backups

Automated backups are configured with:

- Daily backup schedule
- Configurable retention period
- Automatic cleanup of old backups
- Error handling and logging

## Security

- Password protection for cache access
- Bind address configuration
- Connection limits
- Secure configuration file permissions

## Examples

### Redis with Monitoring and Backups

```nix
{
  services.nix-mox.cache-server = {
    enable = true;
    cacheType = "redis";
    bindAddress = "127.0.0.1";
    maxMemory = 2048;
    evictionPolicy = "allkeys-lru";
    persistence = true;
    password = "redis-password";
    enableMonitoring = true;
    enableBackup = true;
    backupRetention = 14;
  };
}
```

### Memcached for High Performance

```nix
{
  services.nix-mox.cache-server = {
    enable = true;
    cacheType = "memcached";
    bindAddress = "0.0.0.0";
    maxMemory = 4096;
    maxConnections = 2048;
    enableMonitoring = true;
  };
}
```

## Troubleshooting

### Common Issues

1. **Service not starting**: Check systemd logs with `journalctl -u nix-mox-cache-server-<type>`
2. **Port conflicts**: Verify no other services are using the configured ports
3. **Memory issues**: Adjust `maxMemory` based on available system memory
4. **Authentication failures**: Ensure password is correctly configured

### Health Check Failures

The template includes detailed error messages for:
- Service not running
- Port not listening
- Cache server not responding
- Monitoring endpoint unavailable

## Fragment System

The template uses a fragment-based architecture for better maintainability:

- **Modular Design**: Each aspect (base, redis, memcached, monitoring, backup) is in its own fragment
- **Conditional Loading**: Fragments are only loaded when relevant options are enabled
- **Easy Extension**: New cache types or features can be added as new fragments
- **Clear Separation**: Configuration, validation, and implementation are clearly separated

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This template is licensed under the MIT License.
