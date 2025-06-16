# Template Overrides

Override specific files while maintaining template functionality.

```mermaid
graph TD
    A[Template Overrides] --> B[Original Template]
    A --> C[Override Files]
    B --> D[Default Files]
    C --> E[Custom Files]
    D --> F[Final Template]
    E --> F
    E --> G[Config Files]
    E --> H[Scripts]
    E --> I[Assets]
```

## Configuration

```nix
# configuration.nix
{
  services.nix-mox.templates = {
    enable = true;
    templates = [ "web-server" ];
    templateVariables = {
      admin_user = "override-admin";
      domain = "should-not-be-used.com";
    };
    templateOverrides = {
      "web-server" = {
        files = ./my-web-server-overrides;
        paths = [
          "nginx/conf.d"
          "scripts"
          "static"
        ];
        fileTypes = [
          "*.conf"
          "*.sh"
          "*.html"
        ];
        conditions = {
          "nginx/conf.d/*.conf" = "environment == 'production'";
          "scripts/*.sh" = "debug_mode == true";
        };
      };
    };
  };
}
```

## Override Structure

```bash
my-web-server-overrides/
├── nginx/
│   ├── conf.d/
│   │   ├── default.conf
│   │   └── ssl.conf
│   └── nginx.conf
├── scripts/
│   ├── start.sh
│   └── healthcheck.sh
├── static/
│   ├── index.html
│   └── assets/
└── info.txt
```

## Examples

### Config Override

```nginx
# my-web-server-overrides/nginx/conf.d/default.conf
server {
    listen 80;
    server_name @domain@;
    
    location / {
        root /var/www/custom;
        try_files $uri $uri/ /index.html;
    }
    
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
```

### Script Override

```bash
# my-web-server-overrides/scripts/start.sh
#!/bin/bash
echo "Starting custom web server for @domain@"
echo "Environment: @environment@"

if [ "@debug_mode@" = "true" ]; then
    nginx -g 'daemon off;'
else
    nginx
fi
```

### Asset Override

```html
<!-- my-web-server-overrides/static/index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>@domain@ - Custom Site</title>
    <link rel="stylesheet" href="/assets/css/custom.css">
</head>
<body>
    <h1>Welcome to @domain@</h1>
    <p>Admin: @admin_user@</p>
</body>
</html>
```

## Rules

### File Matching

- Match original structure
- Override specified files
- Keep others unchanged
- Support variables

### Path Matching

- Override directories
- Override patterns
- Use conditions
- Keep structure

## Use Cases

### Custom Errors

```nix
templateOverrides = {
  "web-server" = {
    files = ./custom-errors;
    paths = ["nginx/error_pages"];
  };
};
```

### Custom SSL

```nix
templateOverrides = {
  "web-server" = {
    files = ./custom-ssl;
    paths = ["nginx/ssl"];
    conditions = {
      "nginx/ssl/*.conf" = "enableSSL == true";
    };
  };
};
```

## Verification

1. Check overrides:

   ```bash
   ls -R /etc/nginx/conf.d/
   ```

2. Verify variables:

   ```bash
   grep -r "@variable_name@" /etc/nginx/
   ```

3. Test scripts:

   ```bash
   /etc/nginx/scripts/start.sh
   ```

## Next Steps

- [Template Variables](../05-variables) in overrides
- [Template Composition](../03-composition) with overrides
- [Template Inheritance](../04-inheritance) with custom
