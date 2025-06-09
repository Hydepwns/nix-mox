# Monitoring Example: Prometheus + Grafana

This directory contains example configs for setting up Prometheus and Grafana to monitor your Proxmox, NixOS, and Windows systems. The configuration includes CI/CD support, enhanced security, and automated monitoring.

- `prometheus.yml`: Example Prometheus scrape config
- `grafana/`: Example Grafana dashboard JSONs and provisioning configs
- `prometheus.nix`: NixOS module for Prometheus with CI/CD support
- `grafana/grafana.nix`: NixOS module for Grafana with enhanced features

---

For general instructions on using, customizing, and best practices for templates, see [../USAGE.md](../USAGE.md).

## Features

- CI/CD integration with environment-specific configurations
- Enhanced security with secret management
- Automated dashboard provisioning
- Self-monitoring capabilities
- Improved error handling and logging
- Automatic service recovery

## NixOS Module Examples

### Prometheus

- Use `prometheus.nix` to deploy Prometheus with the provided `prometheus.yml` config:

  ```nix
  imports = [ ./prometheus.nix ];
  ```

- Prometheus will listen on port 9090 by default
- Includes node_exporter for system metrics
- Enhanced logging and error handling
- CI/CD support with debug logging in CI environment

### Grafana

- Use `grafana/grafana.nix` to deploy Grafana with Prometheus as a data source:

  ```nix
  imports = [ ./grafana/grafana.nix ];
  ```

- Place dashboard JSON files in `grafana/dashboards/` to auto-provision them
- Enhanced security with secret management
- Automatic plugin installation
- CI/CD support with environment-specific settings

## Security Best Practices

1. **Secret Management**:
   - Store sensitive data in `/run/secrets/`
   - Use different passwords for CI and production
   - Enable secure cookies and disable embedding

2. **Access Control**:
   - Restrict dashboard deletion
   - Disable OAuth auto-login
   - Use secure HTTP settings

3. **Monitoring**:
   - Monitor the monitoring stack itself
   - Collect system metrics
   - Enable detailed logging in CI

## CI/CD Integration

1. **Environment Detection**:
   - Set `CI=true` for CI environment
   - Debug logging in CI
   - Simplified security in CI

2. **Automated Testing**:
   - Service health checks
   - Dashboard validation
   - Data source verification

3. **Deployment**:
   - Automatic directory creation
   - Permission management
   - Service recovery

## Example Dashboard

- A sample Node Exporter dashboard is provided in `grafana/dashboards/node-exporter-sample.json`
- Access Grafana at <http://localhost:3000>
- Default credentials (change in production):
  - Username: admin
  - Password: admin (CI) or from secrets (production)

## Troubleshooting

1. **Service Issues**:
   - Check logs: `journalctl -u prometheus` or `journalctl -u grafana`
   - Verify permissions on data directories
   - Check firewall settings

2. **Dashboard Problems**:
   - Verify data source connection
   - Check dashboard JSON syntax
   - Validate metric names

3. **CI/CD Issues**:
   - Verify environment variables
   - Check service status
   - Review debug logs
