# Containerized Services Example

This directory contains example configurations for running services in containers, using both LXC (Proxmox-native) and Docker (via NixOS modules). The configurations include CI/CD support, enhanced security, and monitoring capabilities.

- `lxc/`: Example LXC container config with cloud-init support
- `docker/`: Example Docker service config with monitoring

---

For general instructions on using, customizing, and best practices for templates, see [USAGE.md](../templates/USAGE.md).

## Features

- CI/CD integration with environment-specific configurations
- Enhanced security with audit logging
- Automated monitoring with Prometheus
- Cloud-init support for LXC containers
- Resource management and limits
- Automatic updates and maintenance

## Container Types

### LXC Containers
- NixOS-based containers
- Cloud-init support
- Enhanced security features
- System monitoring
- Automatic updates

### Docker Containers
- Resource limits and monitoring
- Health checks
- Volume management
- Network isolation
- Logging and metrics

## Using This Template

### 1. LXC Container Setup
```nix
# Example: Basic LXC container
imports = [ ./lxc/default.nix ];

# Customize settings
networking.hostName = "my-container";
services.openssh.enable = true;
```

### 2. Docker Container Setup
```nix
# Example: Docker service
imports = [ ./docker/alpine-example.nix ];

# Customize settings
virtualisation.oci-containers.containers.myapp = {
  image = "myapp:latest";
  ports = [ "8080:80" ];
};
```

## Configuration Options

### LXC Options
- Hostname and networking
- Security settings
- User management
- Service configuration
- Monitoring setup

### Docker Options
- Container resources
- Volume mounts
- Network settings
- Health checks
- Environment variables

## CI/CD Integration

1. **Environment Detection**:
   - Set `CI=true` for CI environment
   - Debug logging in CI
   - Simplified security in CI

2. **Automated Testing**:
   - Container health checks
   - Service validation
   - Resource monitoring

3. **Deployment**:
   - Automatic updates
   - Configuration management
   - State persistence

## Monitoring

### Prometheus Integration
- Container metrics
- System statistics
- Resource usage
- Health status

### Logging
- Container logs
- System logs
- Audit logs
- Performance metrics

## Security Best Practices

1. **Access Control**:
   - SSH key authentication
   - Disable password login
   - Firewall rules
   - Resource limits

2. **Monitoring**:
   - Audit logging
   - Security scanning
   - Performance tracking
   - Health checks

3. **Updates**:
   - Automatic security updates
   - Version control
   - Backup procedures
   - Rollback support

## Troubleshooting

1. **Container Issues**:
   - Check logs: `journalctl -u container-name`
   - Verify networking
   - Check resource usage
   - Validate configuration

2. **Docker Problems**:
   - Container logs: `docker logs container-name`
   - Network connectivity
   - Volume mounts
   - Health status

3. **CI/CD Issues**:
   - Environment variables
   - Build logs
   - Test results
   - Deployment status

## Best Practices

1. **Container Management**:
   - Use version control
   - Document configurations
   - Monitor resources
   - Regular updates

2. **Security**:
   - Regular audits
   - Access control
   - Network isolation
   - Resource limits

3. **Monitoring**:
   - Set up alerts
   - Track metrics
   - Log analysis
   - Performance tuning
