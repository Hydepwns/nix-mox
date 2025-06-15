# Load Balancer Template

This template provides a flexible and powerful load balancing solution with support for both HAProxy and Nginx. It includes features for high availability, health checks, monitoring, and statistics.

## Features

- Support for multiple load balancer types:
  - HAProxy
  - Nginx
- Health checks for backend servers
- Statistics page with authentication
- Prometheus monitoring integration
- Multiple load balancing algorithms
- Sticky session support
- Custom configuration options
- Error handling and logging

## Usage

### Basic Configuration

```nix
services.nix-mox.load-balancer = {
  enable = true;
  lbType = "haproxy";  # or "nginx"
  enableStats = true;
  statsUser = "admin";
  statsPassword = "secure_password";
  enableMonitoring = true;
  backends = [
    {
      name = "web";
      domain = "example.com";
      algorithm = "roundrobin";
      servers = [
        {
          name = "web1";
          address = "192.168.1.10";
          port = 8080;
        }
        {
          name = "web2";
          address = "192.168.1.11";
          port = 8080;
        }
      ];
      healthCheck = "GET /health";
      sticky = true;
    }
  ];
};
```

### Advanced Configuration

```nix
services.nix-mox.load-balancer = {
  enable = true;
  lbType = "nginx";
  enableStats = true;
  statsUser = "admin";
  statsPassword = "secure_password";
  enableMonitoring = true;
  backends = [
    {
      name = "api";
      domain = "api.example.com";
      algorithm = "leastconn";
      servers = [
        {
          name = "api1";
          address = "192.168.1.20";
          port = 3000;
        }
        {
          name = "api2";
          address = "192.168.1.21";
          port = 3000;
        }
      ];
      healthCheck = "GET /api/health";
      sticky = false;
    }
    {
      name = "static";
      domain = "static.example.com";
      algorithm = "roundrobin";
      servers = [
        {
          name = "static1";
          address = "192.168.1.30";
          port = 80;
        }
        {
          name = "static2";
          address = "192.168.1.31";
          port = 80;
        }
      ];
    }
  ];
  customConfig = {
    maxConnections = 10000;
    timeout = "30s";
  };
};
```

## Configuration Options

### Load Balancer Type

- `lbType`: Type of load balancer to use
  - Options: "haproxy" or "nginx"
  - Default: "haproxy"

### Statistics

- `enableStats`: Enable statistics page
  - Default: true
- `statsUser`: Username for statistics page
  - Default: "admin"
- `statsPassword`: Password for statistics page
  - Required when stats are enabled

### Monitoring

- `enableMonitoring`: Enable Prometheus monitoring
  - Default: true

### Backends

Each backend configuration includes:

- `name`: Name of the backend
- `domain`: Domain name for the backend
- `algorithm`: Load balancing algorithm
  - Options: "roundrobin", "leastconn", "first", "source", "uri", "url_param", "hdr", "rdp-cookie"
  - Default: "roundrobin"
- `servers`: List of backend servers
  - `name`: Name of the server
  - `address`: Address of the server
  - `port`: Port of the server
- `healthCheck`: Health check configuration
  - Optional
  - Format: "METHOD /path"
- `sticky`: Enable sticky sessions
  - Optional
  - Default: false

### Custom Configuration

- `customConfig`: Additional load balancer configuration
  - Type: attribute set
  - Optional

## Health Checks

The template performs the following health checks:

1. Load balancer service status
2. Port availability
3. Statistics page (if enabled)
4. Backend server health

## Statistics Page

### HAProxy

- URL: http://localhost:8404/stats
- Authentication required
- Real-time statistics
- Connection status
- Server health

### Nginx

- URL: http://localhost:8080/status
- Basic statistics
- Connection status
- Server health

## Monitoring

### Prometheus Integration

- HAProxy exporter: Port 9101
- Nginx exporter: Port 9101
- Metrics available:
  - Connection counts
  - Request rates
  - Response times
  - Error rates
  - Server health

## Error Handling

The template uses the standardized error handling module for:

- Configuration validation
- Service status checks
- Health check failures
- Monitoring setup
- Logging

## Examples

### Basic HAProxy Setup

```nix
services.nix-mox.load-balancer = {
  enable = true;
  lbType = "haproxy";
  enableStats = true;
  statsUser = "admin";
  statsPassword = "secure_password";
  backends = [
    {
      name = "web";
      domain = "example.com";
      servers = [
        {
          name = "web1";
          address = "192.168.1.10";
          port = 8080;
        }
      ];
    }
  ];
};
```

### Nginx with Multiple Backends

```nix
services.nix-mox.load-balancer = {
  enable = true;
  lbType = "nginx";
  enableStats = true;
  statsUser = "admin";
  statsPassword = "secure_password";
  backends = [
    {
      name = "api";
      domain = "api.example.com";
      algorithm = "leastconn";
      servers = [
        {
          name = "api1";
          address = "192.168.1.20";
          port = 3000;
        }
        {
          name = "api2";
          address = "192.168.1.21";
          port = 3000;
        }
      ];
      healthCheck = "GET /api/health";
    }
    {
      name = "static";
      domain = "static.example.com";
      servers = [
        {
          name = "static1";
          address = "192.168.1.30";
          port = 80;
        }
      ];
    }
  ];
};
```

## Troubleshooting

### Common Issues

1. Service not starting
   - Check systemd logs: `journalctl -u nix-mox-load-balancer-{haproxy,nginx}`
   - Verify configuration syntax
   - Check port availability

2. Backend servers not responding
   - Verify server addresses and ports
   - Check firewall rules
   - Test health check endpoints

3. Statistics page not accessible
   - Verify stats are enabled
   - Check authentication credentials
   - Verify port availability

4. Monitoring not working
   - Check Prometheus exporter status
   - Verify port availability
   - Check Prometheus configuration

### Logs

- Systemd logs: `journalctl -u nix-mox-load-balancer-{haproxy,nginx}`
- HAProxy logs: `/var/log/haproxy/haproxy.log`
- Nginx logs: `/var/log/nginx/error.log`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This template is licensed under the MIT License. 