# Migration Guide

This guide is for users migrating from an older version of `nix-mox` to the current version.

## Key Changes

- **Centralized Configuration**: All template settings are now managed under `services.nix-mox.templates` in your `configuration.nix`.
- **No More Manual Scripts**: You no longer need to manually run installation scripts for templates.
- **Rich Customization**: New features like `customOptions`, `templateVariables`, `templateOverrides`, composition, and inheritance provide powerful ways to tailor templates.

## Migration Steps

### 1. Update Your Flake Input

Ensure your `flake.nix` is pointing to the latest version of `nix-mox`.

### 2. Move to the `templates` Module

**Old method (example):** Manually running an install script.

```bash
./templates/web-server/install.sh
```

**New method:**
Enable the template in your `configuration.nix`.

```nix
# in configuration.nix
services.nix-mox.templates = {
  enable = true;
  templates = [ "web-server" ];
};
```

### 3. Convert Configuration to `customOptions`

**Old method:** Editing a config file inside `templates/web-server/`.

```nginx
# inside templates/web-server/nginx.conf
listen 8080;
```

**New method:** Use the structured options for that template.

```nix
# in configuration.nix
services.nix-mox.templates.customOptions = {
  web-server = {
    port = 8080; # Fictional example, check template for actual options
  };
};
```

### 4. Use `templateVariables` for Dynamic Values

**Old method:**

```bash
sed -i 's/USER/admin/g' some-template-file.conf
```

**New method:**

```nix
# in configuration.nix
services.nix-mox.templates.templateVariables = {
  user = "admin";
};

# In the template file: "Hello, @user@"
```

### 5. Use `templateOverrides` for Deep Customization

**Old method:**
Maintaining your own copy of the `web-server` template.

**New method:**
Point to a directory containing only the files you need to change.

```nix
# in configuration.nix
services.nix-mox.templates.templateOverrides = {
  "web-server" = ./my-custom-web-server-files;
};
```

By following these steps, you can transition your configuration to the new templating system, making your setup more maintainable and powerful.
