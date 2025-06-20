# Grafana Dashboards and Configuration

This directory contains example dashboard JSONs and provisioning configs for Grafana, to visualize metrics from Prometheus.

## Fragment System

The Grafana configuration has been moved to the fragment system. Use the `fragments/grafana.nix` fragment instead of the old `grafana.nix` file.

### Usage

1. Import the Grafana fragment into your NixOS configuration:

   ```nix
   imports = [ ./fragments/grafana.nix ];
   ```

2. By default, Grafana will be available at <http://localhost:3000> (admin/admin).
3. Prometheus is pre-configured as a data source (<http://localhost:9090>).
4. Place dashboard JSON files in `/var/lib/grafana/dashboards` to auto-provision them.
5. Change the admin password and domain in the fragment before production use.

## Dashboards

- `dashboards/node-exporter-sample.json`: Sample Node Exporter dashboard
- Add your own dashboard JSON files to the `dashboards/` directory

## Fragment Features

The Grafana fragment includes:

- Web-based visualization
- Dashboard provisioning
- Data source configuration
- Security settings
- Plugin management
- CI/CD integration

See the fragment for more customization options and the main [README-fragments.md](../README-fragments.md) for detailed documentation.
