# Troubleshooting Guide

This guide helps you resolve common issues with `nix-mox` templates.

## Common Issues

### 1. Template Not Found

**Symptom:** You receive an error similar to `the name 'template-name' is not in the enumeration`.

**Cause:** The template name specified in `services.nix-mox.templates.templates` is misspelled or does not exist.

**Solution:**

- Double-check the spelling of the template name in your `configuration.nix`.
- Ensure the template you are trying to use is defined in `modules/templates.nix`.
- If you are using a custom template, make sure it is correctly added to the `templates` attribute set.

### 2. Dependency Errors

**Symptom:** An error occurs during the build process indicating a dependency is not found, such as `Dependency 'some-package' not found`.

**Cause:** A package listed in a template's `dependencies` is not available in the system's `pkgs`.

**Solution:**

- Verify that all dependencies listed in the template's definition in `modules/templates.nix` are valid package names in your Nixpkgs version.
- If a dependency is from a custom overlay or package set, ensure that it is correctly imported and accessible.

### 3. Variable Substitution Not Working

**Symptom:** Files in your template contain raw `@variable@` strings instead of the substituted values.

**Cause:**

- The `templateVariables` option is not correctly configured.
- The file you expect to be substituted was not processed.

**Solution:**

- Ensure that `services.nix-mox.templates.templateVariables` is set in your `configuration.nix`.
- Check that the variable names in your template files match the keys in the `templateVariables` attrset exactly (e.g., `@admin_user@` matches `{ admin_user = "..."; }`).
- The substitution only runs on files that are part of the template's source directory. It does not apply to files added via overrides after the fact.

### 4. Override Conflicts

**Symptom:** Files you intended to override with `templateOverrides` are not being replaced.

**Cause:**

- The path provided in `templateOverrides` is incorrect.
- The file structure in your override directory does not match the file structure of the original template.

**Solution:**

- Verify that the path in `services.nix-mox.templates.templateOverrides` points to the correct directory.
- The file paths in your override directory must be relative to the template's root. For example, to override `templates/web-server/nginx.conf`, your override directory should contain `nginx.conf`.
- Filenames and paths must match exactly.

### 5. Systemd Service Failures

**Symptom:** A systemd service for a template fails to start.

**Cause:**

- The scripts executed by the service are failing.
- There's a configuration error in the template's `customOptions`.

**Solution:**

- Use `systemctl status <service-name>.service` to view the status and recent logs of the service.
- Use `journalctl -u <service-name>.service` to get more detailed logs.
- Review your `customOptions` for the failing template to ensure all values are correct.
- Manually run the template's main script (located in `/run/current-system/sw/bin/nix-mox-template-...`) to see if it produces any errors.
