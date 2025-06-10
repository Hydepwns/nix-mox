# ZFS SSD Caching Template

This template provides automated configuration for ZFS SSD caching using either L2ARC or Special VDEVs. It includes comprehensive monitoring, health checks, and automated maintenance features.

## Features

- **Flexible Caching Options**
  - Support for both L2ARC and Special VDEVs
  - Configurable cache mode (mirror or stripe)
  - Automatic or manual cache size configuration
  - Device health monitoring and validation

- **Enhanced Monitoring**
  - Prometheus metrics integration
  - Grafana dashboard support
  - Detailed logging with multiple log levels
  - Health status monitoring for devices and pools

- **Automated Maintenance**
  - Configurable auto-scrub schedules
  - Automated TRIM support
  - Health check automation
  - Retry mechanisms for operations

- **CI/CD Support**
  - Comprehensive test suite
  - Mocked commands for testing
  - CI-friendly logging
  - Automated validation

## Configuration

### Basic Configuration

```nix
{
  services.zfs-ssd-caching = {
    poolName = "rpool";
    devicePattern = "/dev/nvme*n1";
    cacheType = "l2arc";  # or "special"
    cacheMode = "mirror"; # or "stripe"
    enableLogging = true;
  };
}
```

### Advanced Configuration

```nix
{
  services.zfs-ssd-caching = {
    # Basic settings
    poolName = "rpool";
    devicePattern = "/dev/nvme*n1";
    cacheType = "l2arc";
    cacheMode = "mirror";
    
    # Cache configuration
    cacheSize = "auto";  # or specific size like "100G"
    
    # Monitoring settings
    enableMonitoring = true;
    enableMetrics = true;
    
    # Maintenance settings
    enableAutoScrub = true;
    scrubInterval = "weekly";
    enableAutoTrim = true;
    trimInterval = "weekly";
    
    # Error handling
    maxRetries = 3;
    retryDelay = 5;
    enableLogging = true;
  };
}
```

## Monitoring

### Prometheus Integration

The template automatically configures Prometheus to collect ZFS metrics when `enableMetrics` is set to true. Metrics include:

- Pool health status
- Cache utilization
- Device health
- Performance metrics

### Grafana Integration

When `enableMonitoring` is enabled, the template automatically configures a Grafana data source for ZFS metrics. A default dashboard is provided with:

- Pool status overview
- Cache performance graphs
- Device health status
- Maintenance schedule

## Testing

The template includes a comprehensive test suite that can be run using:

```bash
nix-build tests/zfs-ssd-caching-test.nix
```

The test suite includes:

1. Basic pool detection
2. Device health checks
3. Cache size calculations
4. Service management
5. Log verification
6. Pool health monitoring
7. Cache operations
8. Maintenance configuration

## CI/CD Integration

The template is designed to work seamlessly in CI/CD environments:

- Set `CI=true` to enable CI mode
- Set `TEST=true` to enable test mode
- Logs are automatically written to `/var/log/zfs-ssd-caching.log` in CI mode
- Mocked commands are available for testing

## Error Handling

The template includes comprehensive error handling:

- Automatic retries for failed operations
- Detailed error logging
- Health checks before operations
- Graceful failure handling

## Best Practices

1. **Cache Sizing**
   - Use `cacheSize = "auto"` for automatic sizing
   - Consider pool size when setting manual cache sizes
   - Monitor cache hit rates

2. **Health Monitoring**
   - Enable `enableMonitoring` for production use
   - Regularly check Grafana dashboards
   - Set up alerts for critical issues

3. **Maintenance**
   - Enable auto-scrub for data integrity
   - Configure TRIM for optimal performance
   - Monitor maintenance logs

4. **Testing**
   - Run tests before deployment
   - Verify configuration in test environment
   - Monitor test coverage

## Troubleshooting

### Common Issues

1. **Device Not Found**
   - Verify device pattern
   - Check device permissions
   - Ensure device is healthy

2. **Pool Not Found**
   - Verify pool name
   - Check pool import status
   - Verify pool health

3. **Cache Addition Failed**
   - Check device health
   - Verify pool status
   - Check available space

### Logging

Logs are available in:

- System journal: `journalctl -u zfs-ssd-caching`
- Log file: `/var/log/zfs-ssd-caching.log` (in CI mode)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

## License

This template is licensed under the MIT License.
