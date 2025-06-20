# Monitoring Template: Prometheus + Grafana

This directory contains a **fragment-based monitoring template** for setting up Prometheus and Grafana to monitor your Proxmox, NixOS, and Windows systems. The configuration includes CI/CD support, enhanced security, and automated monitoring.

## 🧩 Fragment System

This template now uses a **fragment system** that allows you to compose monitoring configurations from reusable, focused modules:

```bash
fragments/
├── prometheus.nix      # Prometheus metrics collection
├── grafana.nix         # Grafana visualization
├── node-exporter.nix   # System metrics collection
└── alertmanager.nix    # Alert routing and management
```

### Quick Start with Fragments

```nix
# Complete monitoring stack
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./fragments/prometheus.nix
    ./fragments/grafana.nix
    ./fragments/node-exporter.nix
    ./fragments/alertmanager.nix
  ];
}
```

For detailed fragment system documentation, see [README-fragments.md](./README-fragments.md).

---

For general instructions on using, customizing, and best practices for templates, see [../USAGE.md](../USAGE.md).

## Features

- **Fragment System**: Modular, reusable monitoring components
- CI/CD integration with environment-specific configurations
- Enhanced security with secret management
- Automated dashboard provisioning
- Self-monitoring capabilities
- Improved error handling and logging
- Automatic service recovery

## NixOS Module Examples

### Complete Monitoring Stack

Use the main `monitoring.nix` to deploy the complete monitoring stack:

```nix
imports = [ ./monitoring.nix ];
```

### Individual Components

#### Prometheus

- Use `fragments/prometheus.nix` to deploy Prometheus with the provided `prometheus.yml` config:

  ```nix
  imports = [ ./fragments/prometheus.nix ];
  ```

- Prometheus will listen on port 9090 by default
- Includes node_exporter for system metrics
- Enhanced logging and error handling
- CI/CD support with debug logging in CI environment

#### Grafana

- Use `fragments/grafana.nix` to deploy Grafana with Prometheus as a data source:

  ```nix
  imports = [ ./fragments/grafana.nix ];
  ```

- Place dashboard JSON files in `grafana/dashboards/` to auto-provision them
- Enhanced security with secret management
- Automatic plugin installation
- CI/CD support with environment-specific settings

#### Node Exporter

- Use `fragments/node-exporter.nix` for system metrics collection:

  ```nix
  imports = [ ./fragments/node-exporter.nix ];
  ```

- Collects comprehensive system metrics
- Hardware monitoring capabilities
- Network and filesystem statistics

#### Alertmanager

- Use `fragments/alertmanager.nix` for alert routing and management:

  ```nix
  imports = [ ./fragments/alertmanager.nix ];
  ```

- Alert routing and silencing
- Notification management
- Webhook integration

## Example Configurations

The `examples/` directory contains ready-to-use configurations:

- `complete-stack.nix`: Full monitoring stack with all components
- `prometheus-only.nix`: Minimal Prometheus + Node Exporter setup
- `grafana-only.nix`: Grafana only (assumes external Prometheus)

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

## Ports

| Service | Port | Description |
|---------|------|-------------|
| Prometheus | 9090 | Metrics collection and querying |
| Grafana | 3000 | Web-based visualization |
| Node Exporter | 9100 | System metrics collection |
| Alertmanager | 9093 | Alert routing and management |

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

4. **Fragment Issues**:
   - Ensure all required fragments are imported
   - Check for configuration conflicts
   - Verify fragment dependencies

## Migration from Old System

The old monolithic approach is still supported for backward compatibility. To migrate to the fragment system:

1. **Start with fragments**: Use the new fragment system for new monitoring setups
2. **Gradually migrate**: Convert existing monitoring configurations one by one
3. **Test thoroughly**: Ensure all functionality works after migration

See [README-fragments.md](./README-fragments.md) for detailed migration guidance.
