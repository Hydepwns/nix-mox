# Migration Guide

This guide is for users who are migrating from an older version of `nix-mox` (before the introduction of the unified template module) to the current version.

## Key Changes

The biggest change is the move from a collection of separate scripts and templates to a centralized, declarative NixOS module for managing templates. This provides a more robust, consistent, and configurable system.

- **Centralized Configuration**: All template settings are now managed under `services.nix-mox.templates` in your `configuration.nix`.
- **No More Manual Scripts**: You no longer need to manually run installation scripts for templates. The system handles this automatically when you enable a template.
- **Rich Customization**: New features like `customOptions`, `templateVariables`, `templateOverrides`, composition, and inheritance provide powerful ways to tailor templates without modifying their source code.

## Migration Steps

### 1. Update Your Flake Input

First, ensure your `flake.nix` is pointing to the latest version of `nix-mox`.

### 2. Move to the `templates` Module

If you were previously enabling templates by manually importing them or running scripts, you should now use the `services.nix-mox.templates` module.

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

If you previously customized a template by editing its files directly, you should now use `customOptions` where possible.

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
    # Most templates expose options for common settings
    port = 8080; # Fictional example, check template for actual options
  };
};
```

Check the `modules/templates.nix` file to see the available `customOptions` for each template.

### 4. Use `templateVariables` for Dynamic Values

If you had scripts that substituted variables into template files, you can now use the global `templateVariables`.

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

If `customOptions` are not sufficient and you need to make significant changes to a template file, use `templateOverrides` instead of maintaining a fork.

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

This is much cleaner and makes it easier to pull in future updates to the base templates.

By following these steps, you can transition your configuration to the new templating system, making your setup more maintainable and powerful.
