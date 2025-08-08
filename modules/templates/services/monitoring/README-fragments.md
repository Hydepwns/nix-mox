# Monitoring Template - Fragment System

This template has been updated to use a **fragment system** that allows you to compose monitoring configurations from reusable, focused modules.

## Fragment System Overview

The fragment system breaks down the monolithic monitoring configuration into focused, reusable components:

```bash
fragments/
├── prometheus.nix      # Prometheus metrics collection
├── grafana.nix         # Grafana visualization
├── node-exporter.nix   # System metrics collection
└── alertmanager.nix    # Alert routing and management
```

## Quick Start with Fragments

### Use Complete Monitoring Stack

```bash
# Complete monitoring stack with all components
nixos-rebuild switch --flake .#monitoring-stack
```

### Use Individual Components

```bash
# Prometheus only
nixos-rebuild switch --flake .#prometheus-only

# Grafana only
nixos-rebuild switch --flake .#grafana-only

# Node Exporter only
nixos-rebuild switch --flake .#node-exporter-only
```

### Create Custom Monitoring Configuration

1. **Create a new configuration file:**

```nix
# examples/my-monitoring.nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/prometheus.nix
    ../fragments/grafana.nix
  ];

  # Add custom configuration
  services.prometheus.extraFlags = [
    "--storage.tsdb.retention.time=30d"
  ];
}
```

2. **Add to flake.nix:**

```nix
nixosConfigurations.my-monitoring = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./examples/my-monitoring.nix
  ];
  specialArgs = { inherit nix-mox inputs; };
};
```

3. **Deploy:**

```bash
nixos-rebuild switch --flake .#my-monitoring
```

## Available Fragments

### Core Monitoring Fragments

- **`prometheus.nix`**: Prometheus metrics collection and storage
- **`grafana.nix`**: Grafana visualization and dashboards
- **`node-exporter.nix`**: System metrics collection
- **`alertmanager.nix`**: Alert routing and management

### Fragment Features

#### Prometheus Fragment

- Metrics collection and storage
- Scrape configuration
- Retention policies
- CI/CD integration
- Enhanced systemd service configuration

#### Grafana Fragment

- Web-based visualization
- Dashboard provisioning
- Data source configuration
- Security settings
- Plugin management

#### Node Exporter Fragment

- System metrics collection
- Hardware monitoring
- Filesystem metrics
- Network statistics
- Process monitoring

#### Alertmanager Fragment

- Alert routing
- Notification management
- Silencing capabilities
- Webhook integration
- Email notifications

## Fragment Composition Examples

### Minimal Monitoring (Prometheus + Node Exporter)

```nix
imports = [
  ../fragments/prometheus.nix
  ../fragments/node-exporter.nix
];
```

### Visualization Stack (Prometheus + Grafana)

```nix
imports = [
  ../fragments/prometheus.nix
  ../fragments/grafana.nix
  ../fragments/node-exporter.nix
];
```

### Complete Monitoring Stack

```nix
imports = [
  ../fragments/prometheus.nix
  ../fragments/grafana.nix
  ../fragments/node-exporter.nix
  ../fragments/alertmanager.nix
];
```

### Alerting Only

```nix
imports = [
  ../fragments/alertmanager.nix
];
```

## Customizing Fragments

### Override Fragment Settings

```nix
{ config, pkgs, inputs, ... }:
{
  imports = [ ../fragments/prometheus.nix ];
  
  # Override Prometheus settings
  services.prometheus.extraFlags = [
    "--storage.tsdb.retention.time=30d"
    "--web.enable-admin-api"
  ];
  
  # Override firewall settings
  networking.firewall.allowedTCPPorts = [ 9090 9100 3000 ];
}
```

### Create Custom Fragments

```nix
# fragments/custom-exporter.nix
{ config, pkgs, inputs, ... }:
{
  services.prometheus.exporters.custom = {
    enable = true;
    port = 9110;
    extraFlags = [ "--config.file=/etc/custom-exporter/config.yml" ];
  };
  
  networking.firewall.allowedTCPPorts = 
    config.networking.firewall.allowedTCPPorts ++ [ 9110 ];
}
```

### Conditional Fragment Loading

```nix
{ config, pkgs, inputs, ... }:
let
  isProduction = config.networking.hostName == "prod-monitoring";
in
{
  imports = [
    ../fragments/prometheus.nix
    ../fragments/node-exporter.nix
  ] ++ (if isProduction then [
    ../fragments/alertmanager.nix
  ] else []);
}
```

## Security Best Practices

### Network Security

```nix
# Only open necessary ports
networking.firewall.allowedTCPPorts = [ 9090 ]; # Prometheus only
# Add more ports as needed: [ 9090 3000 9100 9093 ]
```

### Authentication

```nix
# Grafana security settings
services.grafana.settings.security = {
  admin_user = "admin";
  admin_password = "$(cat /run/secrets/grafana-admin-password)";
  secret_key = "$(cat /run/secrets/grafana-secret-key)";
  cookie_secure = true;
  allow_embedding = false;
};
```

### Service Isolation

```nix
# Create dedicated monitoring user
users.users.monitoring = {
  isSystemUser = true;
  group = "monitoring";
  description = "Monitoring services user";
};
```

## Production Configuration

### High Availability Setup

```nix
# fragments/ha-prometheus.nix
{ config, pkgs, inputs, ... }:
{
  imports = [ ../fragments/prometheus.nix ];
  
  services.prometheus.extraFlags = [
    "--storage.tsdb.retention.time=30d"
    "--web.enable-lifecycle"
    "--web.enable-admin-api"
    "--storage.tsdb.no-lockfile"
  ];
  
  # Add clustering support
  services.prometheus.cluster = {
    enable = true;
    peers = [ "prometheus-1:9090" "prometheus-2:9090" ];
  };
}
```

### Multi-Environment Deployment

```nix
# examples/production-monitoring.nix
{ config, pkgs, inputs, ... }:
let
  environment = "production";
in
{
  imports = [
    ../fragments/prometheus.nix
    ../fragments/grafana.nix
    ../fragments/node-exporter.nix
    ../fragments/alertmanager.nix
  ];

  networking.hostName = "monitoring-${environment}";
  
  # Production-specific settings
  services.prometheus.extraFlags = [
    "--storage.tsdb.retention.time=90d"
    "--web.enable-lifecycle"
  ];
  
  services.grafana.settings.security.cookie_secure = true;
}
```

## Migration from Old System

### Legacy Configurations Still Work

The old monolithic approach is still supported for backward compatibility:

```nix
# Old way (still works)
nixosConfigurations.legacy-monitoring = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./monitoring.nix ];
  specialArgs = { inherit nix-mox inputs; };
};
```

### Migration Path

1. **Start with fragments**: Use the new fragment system for new monitoring setups
2. **Gradually migrate**: Convert existing monitoring configurations one by one
3. **Test thoroughly**: Ensure all functionality works after migration

## Advanced Usage

### Custom Dashboards

```nix
# fragments/custom-dashboards.nix
{ config, pkgs, inputs, ... }:
{
  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "custom";
      orgId = 1;
      folder = "Custom";
      type = "file";
      options.path = "/var/lib/grafana/custom-dashboards";
      disableDeletion = false;
      updateIntervalSeconds = 30;
    }
  ];
  
  # Copy custom dashboard files
  environment.etc."grafana/custom-dashboards" = {
    source = ./dashboards;
    target = "grafana/custom-dashboards";
  };
}
```

### Custom Alert Rules

```nix
# fragments/custom-alerts.nix
{ config, pkgs, inputs, ... }:
{
  services.prometheus.rules = [
    {
      alert = "HighCPUUsage";
      expr = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80";
      for = "5m";
      labels = {
        severity = "warning";
      };
      annotations = {
        summary = "High CPU usage on {{ $labels.instance }}";
        description = "CPU usage is above 80% for more than 5 minutes";
      };
    }
  ];
}
```

### Service Discovery

```nix
# fragments/service-discovery.nix
{ config, pkgs, inputs, ... }:
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "kubernetes-pods";
      kubernetes_sd_configs = [
        {
          role = "pod";
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__meta_kubernetes_pod_annotation_prometheus_io_scrape" ];
          action = "keep";
          regex = true;
        }
      ];
    }
  ];
}
```

## Testing

### Test Configuration Syntax

```bash
nix flake check .#checks.x86_64-linux.monitoring
```

### Test Service Build

```bash
nix build .#nixosConfigurations.monitoring-stack.config.system.build.toplevel
```

### Test in VM

```bash
nix build .#nixosConfigurations.monitoring-stack.config.system.build.vm
./result/bin/run-monitoring-stack-vm
```

## Fragment Reference

### Prometheus Fragment Options

- `services.prometheus.enable`: Enable Prometheus
- `services.prometheus.port`: Prometheus port (default: 9090)
- `services.prometheus.extraFlags`: Additional command line flags
- `services.prometheus.scrapeConfigs`: Scrape job configurations
- `services.prometheus.rules`: Alerting rules

### Grafana Fragment Options

- `services.grafana.enable`: Enable Grafana
- `services.grafana.settings.server.http_port`: Grafana port (default: 3000)
- `services.grafana.settings.security`: Security configuration
- `services.grafana.provision`: Data source and dashboard provisioning

### Node Exporter Fragment Options

- `services.prometheus.exporters.node.enable`: Enable Node Exporter
- `services.prometheus.exporters.node.enabledCollectors`: Enabled collectors
- `services.prometheus.exporters.node.port`: Node Exporter port (default: 9100)

### Alertmanager Fragment Options

- `services.prometheus.alertmanager.enable`: Enable Alertmanager
- `services.prometheus.alertmanager.port`: Alertmanager port (default: 9093)
- `services.prometheus.alertmanager.configuration`: Alert routing configuration

## Contributing

When adding new fragments:

1. **Keep fragments focused**: Each fragment should handle one concern
2. **Document options**: Include comments explaining configuration choices
3. **Provide examples**: Show common usage patterns
4. **Maintain compatibility**: Don't break existing configurations
5. **Test thoroughly**: Ensure fragments work together correctly

## Monitoring Stack Ports

| Service | Port | Description |
|---------|------|-------------|
| Prometheus | 9090 | Metrics collection and querying |
| Grafana | 3000 | Web-based visualization |
| Node Exporter | 9100 | System metrics collection |
| Alertmanager | 9093 | Alert routing and management |

## Useful URLs

- Prometheus: <http://localhost:9090>
- Grafana: <http://localhost:3000> (admin/admin)
- Alertmanager: <http://localhost:9093>
- Node Exporter: <http://localhost:9100/metrics>
