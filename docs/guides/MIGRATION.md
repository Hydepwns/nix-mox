# Migration Guide

## Key Changes

- **Centralized Config**: All template settings under `services.nix-mox.templates`
- **No Manual Scripts**: Automatic template installation
- **Rich Customization**: `customOptions`, `templateVariables`, `templateOverrides`, composition, inheritance

## Migration Steps

### 1. Update Flake Input

Ensure `flake.nix` points to latest version.

### 2. Move to `templates` Module

**Old:**

```bash
./templates/web-server/install.sh
```

**New:**

```nix
services.nix-mox.templates = {
  enable = true;
  templates = [ "web-server" ];
};
```

### 3. Convert to `customOptions`

**Old:**

```nginx
# templates/web-server/nginx.conf
listen 8080;
```

**New:**

```nix
services.nix-mox.templates.customOptions = {
  web-server = {
    port = 8080;
  };
};
```

### 4. Use `templateVariables`

**Old:**

```bash
sed -i 's/USER/admin/g' some-template-file.conf
```

**New:**

```nix
services.nix-mox.templates.templateVariables = {
  user = "admin";
};
# Template: "Hello, @user@"
```

### 5. Use `templateOverrides`

**Old:** Maintain template copy

**New:**

```nix
services.nix-mox.templates.templateOverrides = {
  "web-server" = ./my-custom-web-server-files;
};
```

By following these steps, you can transition your configuration to the new templating system, making your setup more maintainable and powerful.
