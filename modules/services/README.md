# Service Modules

This directory contains service-specific modules and configurations organized by functionality.

## Structure

The service modules are organized into fragments for better maintainability:

- `fragments/base.nix`: Common service configuration options and validation
- `fragments/infisical.nix`: Infisical secret management functionality
- `fragments/tailscale.nix`: Tailscale VPN service management
- `fragments/monitoring.nix`: Service monitoring and health checks
- `services.nix`: Main services module that imports all fragments
- Legacy modules: `infisical.nix`, `tailscale.nix` (for backward compatibility)

## Features

- **Secret Management**: Infisical integration for secure secret handling
- **VPN Services**: Tailscale configuration and health monitoring
- **Service Monitoring**: Comprehensive health checks and status monitoring
- **Error Handling**: Robust error handling and logging throughout
- **Prometheus Integration**: Built-in metrics collection for services

## Usage

### Basic Configuration

```nix
{
  services.nix-mox.services = {
    enable = true;
    enableLogging = true;
    enableHealthChecks = true;
  };
}
```

### Infisical Secret Management

```nix
{
  services.nix-mox.infisical = {
    enable = true;
    tokenFile = "/run/secrets/infisical-token";
    secrets = {
      "my-app" = {
        project = "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890";
        environment = "prod";
        path = "/run/secrets/my-app.env";
      };
      "grafana" = {
        project = "b2c3d4e5-f6a1-b2c3-d4e5-f6a1b2c3d4e5";
        environment = "staging";
        path = "/run/secrets/grafana.env";
        update_timer = {
          enable = true;
          frequency = "hourly";
        };
      };
    };
  };
}
```

### Tailscale VPN Management

```nix
{
  services.nix-mox.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-auth-key";
    enableHealthChecks = true;
    enableLogging = true;
  };
}
```

### Service Monitoring

```nix
{
  services.nix-mox.service-monitoring = {
    enable = true;
    services = {
      "nginx" = {
        name = "nginx";
        check_status = true;
        check_port = 80;
        check_url = "http://localhost/health";
        frequency = "*/1:00";
      };
      "postgresql" = {
        name = "postgresql";
        check_status = true;
        check_port = 5432;
        frequency = "*/5:00";
      };
    };
  };
}
```

## Configuration Options

### Base Service Options

- `enable`: Enable service management modules
- `enableLogging`: Enable detailed service operation logging
- `enableHealthChecks`: Enable service health checks and validation
- `defaultUser`: Default user for service operations
- `defaultGroup`: Default group for service operations

### Infisical Options

- `enable`: Enable declarative secret management with Infisical
- `tokenFile`: Path to a file containing the Infisical authentication token
- `secrets`: Attribute set defining the secrets to fetch from Infisical
  - `project`: The Infisical Project ID to fetch secrets from
  - `environment`: The environment (slug) within the Infisical project
  - `path`: The destination path for the fetched secrets file
  - `update_timer`: Configuration for recurring secret updates
    - `enable`: Enable a recurring timer to refresh the secrets
    - `frequency`: How often to refresh the secrets

### Tailscale Options

- `enable`: Enable Tailscale service management via nix-mox
- `authKeyFile`: Path to a file containing the Tailscale auth key
- `enableHealthChecks`: Enable Tailscale health checks and status monitoring
- `enableLogging`: Enable detailed Tailscale operation logging

### Service Monitoring Options

- `enable`: Enable service monitoring and health checks
- `services`: Configuration for service monitoring
  - `name`: Systemd service name to monitor
  - `check_status`: Check if the service is running
  - `check_port`: Port to check if the service is listening
  - `check_url`: URL to check for HTTP/HTTPS health endpoint
  - `frequency`: How often to check the service

## Fragment System

The service modules use a fragment-based architecture for better maintainability:

- **Modular Design**: Each aspect (base, infisical, tailscale, monitoring) is in its own fragment
- **Conditional Loading**: Fragments are only loaded when relevant options are enabled
- **Easy Extension**: New service types or features can be added as new fragments
- **Clear Separation**: Configuration, validation, and implementation are clearly separated

## Health Checks

The service modules include comprehensive health checks:

1. **Service Status**: Verifies services are running via systemd
2. **Port Availability**: Checks if services are listening on configured ports
3. **HTTP Health**: Validates HTTP/HTTPS health endpoints
4. **Authentication**: Validates service authentication and connectivity
5. **Secret Validation**: Ensures secret files are properly created and accessible

## Monitoring

When monitoring is enabled, the modules automatically configure:

- Prometheus exporters for service metrics
- Systemd service status monitoring
- Network connectivity checks
- Health endpoint validation

## Examples

### Complete Service Setup

```nix
{
  services.nix-mox.services = {
    enable = true;
    enableLogging = true;
    enableHealthChecks = true;
  };

  services.nix-mox.infisical = {
    enable = true;
    tokenFile = "/run/secrets/infisical-token";
    secrets = {
      "app-secrets" = {
        project = "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890";
        environment = "prod";
        path = "/run/secrets/app.env";
        update_timer = {
          enable = true;
          frequency = "daily";
        };
      };
    };
  };

  services.nix-mox.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-auth-key";
    enableHealthChecks = true;
  };

  services.nix-mox.service-monitoring = {
    enable = true;
    services = {
      "nginx" = {
        name = "nginx";
        check_status = true;
        check_port = 80;
        check_url = "http://localhost/health";
        frequency = "*/1:00";
      };
      "app" = {
        name = "my-app";
        check_status = true;
        check_port = 8080;
        frequency = "*/2:00";
      };
    };
  };
}
```

## Troubleshooting

### Common Issues

1. **Infisical token not found**: Ensure the token file exists and has correct permissions
2. **Tailscale authentication failed**: Verify the auth key is valid and the service can access it
3. **Service not found**: Ensure the systemd service name is correct
4. **Port not listening**: Check if the service is configured to listen on the specified port

### Health Check Failures

The modules include detailed error messages for:

- Service not running
- Port not listening
- HTTP health check failures
- Authentication failures
- Secret file creation failures

## Security Considerations

- **Secret Management**: Infisical tokens and auth keys should be stored securely
- **File Permissions**: Ensure secret files have appropriate permissions
- **Network Security**: Tailscale provides secure VPN connectivity
- **Service Isolation**: Each service runs with appropriate user/group permissions
