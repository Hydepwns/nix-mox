# nix-mox Monitoring Setup Guide

> Comprehensive real-time monitoring with Prometheus and Grafana

## 🎯 Overview

nix-mox provides enterprise-grade monitoring capabilities with:
- **Real-time metrics collection** via Prometheus
- **Visual dashboards** with Grafana  
- **Intelligent alerting** with 12+ pre-configured rules
- **Multi-platform support** (Linux, macOS, Windows)

## 🚀 Quick Setup

### 1. Enable Metrics Collection

```bash
# Enable metrics globally
export NIX_MOX_METRICS_ENABLED=true

# Add to your shell profile for persistence
echo 'export NIX_MOX_METRICS_ENABLED=true' >> ~/.bashrc
```

### 2. Start Monitoring Services

```bash
# Include monitoring in your NixOS configuration
sudo nixos-rebuild switch --flake .#nixos

# Or enable the monitoring template
cp modules/templates/services/monitoring/monitoring.nix config/nixos/
```

### 3. Access Dashboards

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Metrics endpoint**: http://localhost:9200/metrics

## 📊 Available Metrics

### Core System Metrics
```
nix_mox_script_executions_total      # Total script executions
nix_mox_script_failures_total        # Script failure count  
nix_mox_script_duration_seconds      # Execution time histogram
nix_mox_memory_usage_percent         # Memory usage percentage
nix_mox_cpu_usage_percent            # CPU usage percentage
nix_mox_disk_usage_percent           # Disk usage percentage
```

### Error & Security Metrics
```
nix_mox_errors_total                 # Errors by type
nix_mox_security_threats_total       # Security threats detected
nix_mox_security_scans_total         # Security scans performed
nix_mox_security_validations_total   # Security validations
```

### Testing & Quality Metrics
```
nix_mox_test_suite_success_rate      # Test success percentage
nix_mox_config_validation_failures_total  # Config failures
nix_mox_platform_errors_total       # Platform-specific errors
```

## 🔧 Configuration

### Prometheus Configuration

Located in `modules/templates/services/monitoring/nix-mox-metrics.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # nix-mox application metrics
  - job_name: 'nix-mox-scripts'
    static_configs:
      - targets: ['localhost:9200']
    scrape_interval: 30s
    
  # Performance monitoring  
  - job_name: 'nix-mox-performance'
    static_configs:
      - targets: ['localhost:9201']
    scrape_interval: 15s

  # Error tracking
  - job_name: 'nix-mox-errors'
    static_configs:
      - targets: ['localhost:9202'] 
    scrape_interval: 10s
```

### Grafana Dashboard

The complete dashboard is available at:
`modules/templates/services/monitoring/grafana/dashboards/nix-mox-overview.json`

**Dashboard Features:**
- Script execution rate and success rate
- Performance percentiles (50th, 95th, 99th)
- Resource usage (CPU, Memory, Disk)
- Error rate by type
- Security threat monitoring

### Alert Rules

Located in `modules/templates/services/monitoring/rules/nix-mox-alerts.yml`:

**Critical Alerts:**
- High script failure rate (>0.1/sec for 2 minutes)
- High error rate (>0.05/sec for 1 minute)  
- Security threats detected (immediate)
- Service downtime (>1 minute)

**Warning Alerts:**
- Performance degradation (95th percentile >30s)
- High memory usage (>85% for 3 minutes)
- Low disk space (>90% for 5 minutes)
- Test suite failures (<95% success rate)

## 🔍 Monitoring Workflows

### Script Execution Monitoring

Automatically wrap scripts with metrics:

```nu
use scripts/lib/metrics.nu *

# Wrap any script execution
wrap_script_with_metrics "my-script" {
    # Your script logic here
    print "Hello, world!"
}
```

### Manual Metrics Collection

```nu
use scripts/lib/metrics.nu *

# Initialize metrics
init_core_metrics

# Track custom metrics
increment_counter "my_custom_counter" {component: "example"}
set_gauge "my_custom_gauge" 42.0
observe_histogram "my_custom_duration" 1.5

# Export metrics
export_metrics_to_file "/tmp/my-metrics.prom"
```

### Performance Monitoring

```nu
use scripts/lib/performance.nu *

# Start performance monitoring
let monitor_id = start_performance_monitor "database_query" {
    query_type: "SELECT",
    table: "users"
}

# ... perform operation ...

# End monitoring (automatically records metrics)
end_performance_monitor $monitor_id
```

### Error Tracking

```nu
use scripts/lib/error-handling.nu *

# Errors are automatically tracked when using handle_script_error
try {
    # Risky operation
} catch {|err|
    handle_script_error "Operation failed" "DATABASE" {
        query: "SELECT * FROM users",
        error: $err
    }
}
```

## 🎨 Dashboard Customization

### Adding Custom Panels

1. **Access Grafana** at http://localhost:3000
2. **Edit dashboard** → Add panel
3. **Select metrics** from nix-mox namespace
4. **Configure visualization** (time series, gauge, etc.)

### Common Queries

```promql
# Script success rate over time
rate(nix_mox_script_executions_total[5m]) - rate(nix_mox_script_failures_total[5m])

# Average script duration
rate(nix_mox_script_duration_seconds_sum[5m]) / rate(nix_mox_script_duration_seconds_count[5m])

# Error rate by platform
sum by (platform) (rate(nix_mox_platform_errors_total[5m]))

# Top failing scripts
topk(5, rate(nix_mox_script_failures_total[5m]))
```

## 🚨 Alerting Setup

### Alertmanager Configuration

```yaml
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
```

### Slack Integration

```yaml
receivers:
- name: 'slack-notifications'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#nix-mox-alerts'
    title: 'nix-mox Alert'
    text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

### Email Notifications

```yaml
receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'admin@example.com'
    from: 'nix-mox@example.com'
    smarthost: 'localhost:587'
    subject: 'nix-mox Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
```

## 🔧 Troubleshooting

### Metrics Not Appearing

1. **Check metrics endpoint**:
   ```bash
   curl http://localhost:9200/metrics
   ```

2. **Verify environment variable**:
   ```bash
   echo $NIX_MOX_METRICS_ENABLED
   ```

3. **Check metrics file**:
   ```bash
   cat /tmp/nix-mox-metrics.prom
   ```

### Grafana Connection Issues

1. **Verify Prometheus datasource**:
   - URL: `http://localhost:9090`
   - Access: `Server (default)`

2. **Check Prometheus targets**:
   - Go to http://localhost:9090/targets
   - Ensure nix-mox endpoints are UP

3. **Restart services**:
   ```bash
   sudo systemctl restart prometheus grafana
   ```

### Performance Impact

Monitoring overhead is minimal:
- **CPU**: <1% additional usage
- **Memory**: ~10MB for metrics collection
- **Disk**: ~1MB/day for metrics storage
- **Network**: ~1KB/sec metrics traffic

### Security Considerations

- **Metrics endpoints** are localhost-only by default
- **No sensitive data** is included in metrics
- **Grafana authentication** should be enabled in production
- **Firewall rules** restrict external access

## 📈 Advanced Scenarios

### Multi-Host Monitoring

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'nix-mox-cluster'
    static_configs:
      - targets: 
        - 'host1:9200'
        - 'host2:9200' 
        - 'host3:9200'
```

### Custom Metrics Export

```nu
use scripts/lib/metrics.nu *

# Create custom metrics
let custom_metrics = [
    (create_counter "deployment_count" "Number of deployments"),
    (create_gauge "service_health" "Service health status"),
    (create_histogram "request_duration" "Request processing time")
]

# Export to different formats
export_metrics_to_file "/tmp/custom-metrics.prom"
```

### Integration with External Systems

```nu
# Push metrics to external collector
def push_to_collector [endpoint: string] {
    let metrics = format_prometheus_metrics
    http post $endpoint $metrics
}

# Webhook for critical alerts  
def send_webhook_alert [alert: record] {
    let payload = {
        text: $"🚨 nix-mox Alert: ($alert.summary)",
        channel: "#alerts",
        username: "nix-mox"
    }
    http post $env.SLACK_WEBHOOK $payload
}
```

## 🎯 Best Practices

1. **Set appropriate scrape intervals** (15-30s for most metrics)
2. **Use labels effectively** for filtering and grouping
3. **Monitor the monitors** - track Prometheus/Grafana health
4. **Regular dashboard reviews** - ensure metrics remain relevant
5. **Alert tuning** - avoid alert fatigue with proper thresholds
6. **Retention policies** - balance storage vs. historical data needs

## 📚 Further Reading

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboard Design](https://grafana.com/docs/grafana/latest/best-practices/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)