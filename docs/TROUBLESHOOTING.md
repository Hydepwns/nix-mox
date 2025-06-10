# Troubleshooting Guide

This guide helps you resolve common issues with `nix-mox` templates.

## Common Issues

### 1. Template Not Found

**Symptom:** Error: `the name 'template-name' is not in the enumeration`.

**Cause:** Misspelled or non-existent template name in `services.nix-mox.templates.templates`.

**Solution:** Check spelling in `configuration.nix` and ensure the template is defined in `modules/templates.nix`.

### 2. Dependency Errors

**Symptom:** Error: `Dependency 'some-package' not found`.

**Cause:** Package not available in system's `pkgs`.

**Solution:** Verify dependencies in `modules/templates.nix` are valid in your Nixpkgs version.

### 3. Variable Substitution Not Working

**Symptom:** Files contain raw `@variable@` strings.

**Cause:** Incorrect `templateVariables` configuration or file not processed.

**Solution:** Ensure `services.nix-mox.templates.templateVariables` is set and variable names match exactly.

### 4. Override Conflicts

**Symptom:** Files not replaced with `templateOverrides`.

**Cause:** Incorrect path or file structure mismatch.

**Solution:** Verify path in `services.nix-mox.templates.templateOverrides` and ensure file structure matches.

### 5. Systemd Service Failures

**Symptom:** Service fails to start.

**Cause:** Script failure or configuration error.

**Solution:** Use `systemctl status <service-name>.service` and `journalctl -u <service-name>.service` for logs. Review `customOptions` and run the template's main script manually.
