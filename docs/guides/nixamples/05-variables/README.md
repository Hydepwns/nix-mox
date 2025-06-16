# Template Variables

Use variables for dynamic configuration values in templates.

```mermaid
graph TD
    A[Template Variables] --> B[Define Variables]
    B --> C[Use in Templates]
    C --> D[Admin User]
    C --> E[Domain Name]
    C --> F[Other Settings]
    D --> G[@admin_user@]
    E --> H[@domain@]
    F --> I[Environment]
    F --> J[Secrets]
    F --> K[Paths]
```

## Configuration

```nix
# configuration.nix
{
  services.nix-mox.templates = {
    enable = true;
    templates = [ "web-server" ];
    templateVariables = {
      # Basic variables
      admin_user = "site-admin";
      domain = "mycoolsite.com";
      
      # Environment
      environment = "production";
      debug_mode = false;
      
      # Paths
      app_root = "/var/www/app";
      api_url = "https://api.${domain}";
      
      # Secrets
      db_password = "@secret:database/password@";
      api_key = "@secret:api/key@";
      
      # Dynamic
      timestamp = "@timestamp@";
      hostname = "@hostname@";
      
      # Lists
      allowed_ips = ["10.0.0.0/8" "192.168.0.0/16"];
      feature_flags = {
        enable_cache = true;
        enable_logging = true;
      };
    };
  };
}
```

## Variable Types

### Basic

```nix
templateVariables = {
  admin_user = "site-admin";
  domain = "mycoolsite.com";
};
```

### Environment

```nix
templateVariables = {
  environment = "production";
  debug_mode = false;
  log_level = "info";
};
```

### Secrets

```nix
templateVariables = {
  db_password = "@secret:database/password@";
  api_key = "@secret:api/key@";
  ssl_cert = "@secret:ssl/cert@";
};
```

### Dynamic

```nix
templateVariables = {
  timestamp = "@timestamp@";
  hostname = "@hostname@";
  random_id = "@random:uuid@";
};
```

## Usage Examples

### Nginx Config

```nginx
server {
    server_name @domain@;
    root @app_root@;
    
    location /admin {
        auth_basic "Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
    
    location /api {
        proxy_pass @api_url@;
        proxy_set_header Host @hostname@;
    }
}
```

### Environment File

```env
APP_ENV=@environment@
DEBUG=@debug_mode@
DB_PASSWORD=@db_password@
API_KEY=@api_key@
```

### Shell Script

```bash
#!/bin/bash
echo "Starting @domain@ on @hostname@"
echo "Environment: @environment@"
echo "Timestamp: @timestamp@"
```

## Resolution

1. Define in `templateVariables`
2. Process before deployment
3. Replace `@variable_name@`
4. Error on undefined
5. Resolve secrets
6. Generate dynamic

## Examples

### Multi-Environment

```nix
templateVariables = {
  environment = "production";
  domain = "prod.${environment}.example.com";
  debug_mode = environment == "development";
};
```

### Secure Config

```nix
templateVariables = {
  db_password = "@secret:database/password@";
  ssl_cert = "@secret:ssl/cert@";
  api_key = "@secret:api/key@";
};
```

## Verification

1. Check substitution:

   ```bash
   grep -r "@variable_name@" /etc/nginx/
   ```

2. Verify secrets:

   ```bash
   echo $DB_PASSWORD
   ```

3. Test dynamic:

   ```bash
   echo $HOSTNAME
   echo $TIMESTAMP
   ```

## Next Steps

- [Template Overrides](../06-overrides) with vars
- [Template Composition](../03-composition) with shared
- [Template Inheritance](../04-inheritance) with inherit
