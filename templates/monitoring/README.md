# Monitoring Example: Prometheus + Grafana

This directory contains example configs for setting up Prometheus and Grafana to monitor your Proxmox, NixOS, and Windows systems.

- `prometheus.yml`: Example Prometheus scrape config
- `grafana/`: Example Grafana dashboard JSONs or provisioning configs

---

For general instructions on using, customizing, and best practices for templates, see [../USAGE.md](../USAGE.md).

## NixOS Module Examples

### Prometheus

- Use `prometheus.nix` to deploy Prometheus with the provided `prometheus.yml` config:

  ```nix
  imports = [ ./prometheus.nix ];
  ```

- Prometheus will listen on port 9090 by default.

### Grafana

- Use `grafana/grafana.nix` to deploy Grafana with Prometheus as a data source:

  ```nix
  imports = [ ./grafana/grafana.nix ];
  ```

- Place dashboard JSON files (e.g., `node-exporter-sample.json`) in `grafana/dashboards/` to auto-provision them.

See comments in each example for further customization options.

## Example Dashboard

- A sample Node Exporter dashboard is provided in `grafana/dashboards/node-exporter-sample.json`.
- Access Grafana at <http://localhost:3000> (admin/admin) and import or view the dashboard.
