# ZFS SSD Caching Example

This directory provides a flexible solution for adding SSDs as special vdevs or L2ARC to your ZFS pool for improved VM disk performance. The configuration includes CI/CD support, enhanced error handling, and monitoring capabilities.

---

For general instructions on using, customizing, and best practices for templates, see [../USAGE.md](../templates/USAGE.md).

## Features

- CI/CD integration with environment-specific configurations
- Enhanced error handling and logging
- Automated device detection and configuration
- Monitoring integration with Prometheus
- Support for both L2ARC and special vdevs
- Configurable device patterns and pool names

## Usage

1. Import the module into your NixOS configuration:

   ```nix
   imports = [ ./zfs-ssd-caching.nix ];
   ```

2. Configure options (optional):

   ```nix
   {
     # Example: Use special vdevs instead of L2ARC
     services.zfs-ssd-caching = {
       useSpecialVdevs = true;
       poolName = "tank";
       devicePattern = "/dev/nvme*n1";
     };
   }
   ```

3. The service will automatically:
   - Detect available NVMe SSDs
   - Add them as L2ARC cache or special vdevs
   - Monitor ZFS performance
   - Handle errors gracefully

## Configuration Options

### Basic Options

- `poolName`: ZFS pool name (default: "rpool")
- `devicePattern`: Glob pattern for NVMe devices (default: "/dev/nvme*n1")
- `useSpecialVdevs`: Use special vdevs instead of L2ARC (default: false)
- `enableLogging`: Enable detailed logging (default: true)

### CI/CD Options

- Set `CI=true` for CI environment
- Debug logging in CI
- Simplified error handling

## Monitoring

The module automatically configures:

- ZFS metrics collection
- Filesystem monitoring
- Disk statistics
- Prometheus integration

Access metrics at `http://localhost:9100/metrics`

## Example Commands

### Manual Configuration

Add a special vdev (metadata/small files):

```bash
zpool add rpool special mirror /dev/nvme0n1 /dev/nvme1n1
```

Add an L2ARC (read cache):

```bash
zpool add rpool cache /dev/nvme2n1
```

## Troubleshooting

1. **Service Issues**:
   - Check logs: `journalctl -u zfs-ssd-caching`
   - Verify device permissions
   - Check pool status: `zpool status`

2. **Device Problems**:
   - Verify device exists: `ls -l /dev/nvme*`
   - Check device status: `nvme smart-log /dev/nvme0n1`
   - Verify pool import: `zpool import`

3. **CI/CD Issues**:
   - Verify environment variables
   - Check service status
   - Review debug logs

## Best Practices

1. **Device Selection**:
   - Use enterprise-grade SSDs for special vdevs
   - Consider endurance ratings for L2ARC
   - Monitor device health regularly

2. **Performance Tuning**:
   - Adjust ARC size based on available RAM
   - Monitor cache hit rates
   - Consider workload patterns

3. **Monitoring**:
   - Set up alerts for device failures
   - Monitor cache performance
   - Track pool health

## Security Considerations

1. **Device Access**:
   - Restrict device permissions
   - Use secure mount options
   - Monitor access patterns

2. **Data Protection**:
   - Regular pool scrubs
   - Backup critical data
   - Monitor pool health
