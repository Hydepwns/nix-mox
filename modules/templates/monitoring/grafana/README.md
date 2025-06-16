# Grafana Example

This directory can contain example dashboard JSONs or provisioning configs for Grafana, to visualize metrics from Prometheus.

## NixOS Module Example

A ready-to-use NixOS module is provided in `grafana.nix` for deploying Grafana with Prometheus as a data source.

### Usage

1. Import `grafana.nix` into your NixOS configuration:

   ```nix
   imports = [ ./grafana/grafana.nix ];
   ```

2. By default, Grafana will be available at <http://localhost:3000> (admin/admin).
3. Prometheus is pre-configured as a data source (<http://localhost:9090>).
4. Place dashboard JSON files in `/var/lib/grafana/dashboards` to auto-provision them.
5. Change the admin password and domain in `grafana.nix` before production use.

See the module for more customization options.
