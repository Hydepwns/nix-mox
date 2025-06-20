# Web Server Template

This template provides comprehensive web server management capabilities for Nginx and Apache, including SSL support, virtual hosts, and monitoring.

## Features

- Support for Nginx and Apache web servers
- SSL certificate management
- Virtual host configuration
- Prometheus monitoring integration
- Health checks
- Custom configuration options
- Error handling and logging

## Usage

### Basic Configuration

```nix
services.nix-mox.web-server = {
  enable = true;
  serverType = "nginx";  # or "apache"
};
```

### Advanced Configuration

```nix
services.nix-mox.web-server = {
  enable = true;
  serverType = "nginx";
  enableSSL = true;
  enableMonitoring = true;
  virtualHosts = [
    {
      name = "example";
      domain = "example.com";
      root = "/var/www/example";
      indexFiles = [ "index.html" "index.php" ];
      proxyPass = "http://localhost:8080";
    }
  ];
  customConfig = {
    # Custom server configuration
    worker_processes = 4;
    worker_connections = 1024;
  };
};
```

## Configuration Options

### `enable`

Enable or disable the web server template.

### `serverType`

Type of web server to use. Available options:

- `nginx`: Nginx web server
- `apache`: Apache web server

### `enableSSL`

Enable or disable SSL support.

### `enableMonitoring`

Enable or disable Prometheus monitoring.

### `virtualHosts`

List of virtual hosts to configure. Each virtual host can have:

- `name`: Name of the virtual host
- `domain`: Domain name
- `root`: Root directory
- `indexFiles`: List of index files to try
- `proxyPass`: Proxy pass URL for API requests

### `customConfig`

Custom server configuration options. See the respective server documentation for available options.

## Health Checks

The template performs the following health checks:

1. Server service status
2. Port availability
3. SSL configuration (if enabled)
4. Log directory existence

## SSL Support

When SSL is enabled, the template:

1. Creates an SSL directory
2. Generates a self-signed certificate if not provided
3. Configures the server to use SSL
4. Sets up SSL virtual hosts

## Virtual Hosts

Virtual hosts can be configured with:

- Custom root directories
- Multiple index files
- API proxy support
- SSL configuration
- Custom server settings

## Monitoring

The template integrates with Prometheus for monitoring:

- Nginx: Exporter runs on port 9180
- Apache: Exporter runs on port 9117

## Error Handling

The template uses the standardized error handling module for consistent error management and logging.

## Examples

### Basic Nginx Setup

```nix
services.nix-mox.web-server = {
  enable = true;
  serverType = "nginx";
  virtualHosts = [
    {
      name = "default";
      domain = "localhost";
      root = "/var/www/html";
    }
  ];
};
```

### Apache with SSL

```nix
services.nix-mox.web-server = {
  enable = true;
  serverType = "apache";
  enableSSL = true;
  virtualHosts = [
    {
      name = "secure";
      domain = "secure.example.com";
      root = "/var/www/secure";
    }
  ];
};
```

### Nginx with API Proxy

```nix
services.nix-mox.web-server = {
  enable = true;
  serverType = "nginx";
  virtualHosts = [
    {
      name = "api";
      domain = "api.example.com";
      root = "/var/www/api";
      proxyPass = "http://localhost:3000";
    }
  ];
};
```

## Troubleshooting

### Common Issues

1. **Server Not Starting**
   - Check service status: `systemctl status nginx` or `systemctl status httpd`
   - Check logs: `journalctl -u nginx` or `journalctl -u httpd`
   - Verify configuration: `nginx -t` or `apache2ctl -t`

2. **SSL Issues**
   - Verify certificate files exist
   - Check certificate permissions
   - Review SSL configuration

3. **Virtual Host Problems**
   - Check virtual host configuration
   - Verify domain resolution
   - Check file permissions

4. **Monitoring Issues**
   - Verify Prometheus exporter is running
   - Check exporter ports are accessible
   - Review Prometheus configuration

### Logs

- Server logs: `journalctl -u nginx` or `journalctl -u httpd`
- Template logs: `journalctl -u nix-mox-web-nginx` or `journalctl -u nix-mox-web-apache`
- Access logs: `/var/log/nginx/access.log` or `/var/log/apache2/access.log`
- Error logs: `/var/log/nginx/error.log` or `/var/log/apache2/error.log`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This template is licensed under the MIT License.
