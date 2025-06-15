# Template Variables

This example demonstrates how to use template variables for dynamic configuration values that can be referenced throughout your templates.

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
    I --> L[@env@]
    J --> M[@secret@]
    K --> N[@path@]
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
      
      # Environment-specific
      environment = "production";
      debug_mode = false;
      
      # Paths and URLs
      app_root = "/var/www/app";
      api_url = "https://api.${domain}";
      
      # Secrets (referenced from external source)
      db_password = "@secret:database/password@";
      api_key = "@secret:api/key@";
      
      # Dynamic values
      timestamp = "@timestamp@";
      hostname = "@hostname@";
      
      # Lists and objects
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

### 1. Basic Variables

```nix
templateVariables = {
  admin_user = "site-admin";
  domain = "mycoolsite.com";
};
```

### 2. Environment Variables

```nix
templateVariables = {
  environment = "production";
  debug_mode = false;
  log_level = "info";
};
```

### 3. Path Variables

```nix
templateVariables = {
  app_root = "/var/www/app";
  log_path = "/var/log/app";
  config_path = "/etc/app";
};
```

### 4. Secret Variables

```nix
templateVariables = {
  db_password = "@secret:database/password@";
  api_key = "@secret:api/key@";
  ssl_cert = "@secret:ssl/cert@";
};
```

### 5. Dynamic Variables

```nix
templateVariables = {
  timestamp = "@timestamp@";
  hostname = "@hostname@";
  random_id = "@random:uuid@";
};
```

## Variable Usage

### In Nginx Configuration

```nginx
server {
    server_name @domain@;
    root @app_root@;
    
    location /admin {
        auth_basic "Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        # @admin_user@ will be replaced with "site-admin"
    }
    
    location /api {
        proxy_pass @api_url@;
        proxy_set_header Host @hostname@;
    }
}
```

### In Environment Files

```env
APP_ENV=@environment@
DEBUG=@debug_mode@
DB_PASSWORD=@db_password@
API_KEY=@api_key@
```

### In Shell Scripts

```bash
#!/bin/bash
echo "Starting @domain@ on @hostname@"
echo "Environment: @environment@"
echo "Timestamp: @timestamp@"
```

## Variable Resolution

1. Variables are defined in `templateVariables`
2. They are processed before template deployment
3. All instances of `@variable_name@` are replaced
4. Undefined variables cause an error
5. Secret variables are resolved from external sources
6. Dynamic variables are generated at runtime

## Use Cases

### 1. Multi-Environment Deployment

```nix
templateVariables = {
  environment = "production";
  domain = "prod.${environment}.example.com";
  debug_mode = environment == "development";
};
```

### 2. Secure Configuration

```nix
templateVariables = {
  db_password = "@secret:database/password@";
  ssl_cert = "@secret:ssl/cert@";
  api_key = "@secret:api/key@";
};
```

### 3. Dynamic Paths

```nix
templateVariables = {
  app_root = "/var/www/${environment}/app";
  log_path = "/var/log/${environment}/app";
  config_path = "/etc/${environment}/app";
};
```

## Expected Outcome

After applying this configuration:

- All `@variable_name@` references will be replaced
- Secret variables will be securely resolved
- Dynamic variables will be generated
- Environment-specific values will be set

## Verification

1. Check variable substitution:

   ```bash
   grep -r "@variable_name@" /etc/nginx/
   ```

2. Verify secret resolution:

   ```bash
   echo $DB_PASSWORD
   ```

3. Test dynamic variables:

   ```bash
   echo $HOSTNAME
   echo $TIMESTAMP
   ```

## Next Steps

- Try [Template Overrides](../06-overrides) with variables
- Learn about [Template Composition](../03-composition) with shared variables
- Explore [Template Inheritance](../04-inheritance) with variable inheritance
