# Troubleshooting Guide

This guide provides solutions to common issues encountered while working with the `nix-mox` repository.

## Table of Contents

- [CI/CD Failures](#cicd-failures)
  - [Cachix Signature Verification Failed](#cachix-signature-verification-failed)
- [Build Failures](#build-failures)
- [Local Development Issues](#local-development-issues)

---

## CI/CD Failures

### Cachix Signature Verification Failed

**Symptom:**

The CI job fails during the "Push to Cachix" or "Setup Cachix" step with an error similar to this:

```
[Error] FailureResponse ... {"error":"Signature verification failed. The signing key you're using doesn't match any of the public keys for binary cache nix-mox..."}
```

**Cause:**

This error occurs when the `CACHIX_SIGNING_KEY` used by the GitHub Actions workflow is missing, incorrect, or does not correspond to the public key configured for the `nix-mox` Cachix cache.

The `nix-mox` cache is configured to require signed uploads, and the public key is defined in `flake.nix` and other configuration files within this repository.

**Solution:**

You need to ensure that the correct private signing key is stored in your repository's GitHub Actions secrets.

1. **Retrieve your Cachix Signing Key:**

    If you have the `cachix` CLI tool installed and configured, you can retrieve your signing key with the following command:

    ```bash
    cachix signing-key nix-mox
    ```

    This will print the private key to your terminal. Copy this key.

    If you have lost the key, you may need to regenerate it. Be aware that this will invalidate the old public key, and you will need to update it in all places it is used (like `flake.nix`). You can regenerate it with `cachix signing-key nix-mox --regenerate`.

2. **Add the Signing Key to GitHub Secrets:**

    - Navigate to your GitHub repository's page.
    - Go to **Settings** > **Secrets and variables** > **Actions**.
    - Click on the **Secrets** tab.
    - Click **New repository secret**.
    - Set the **Name** to `CACHIX_SIGNING_KEY`.
    - Paste the private key you copied into the **Secret** field.
    - Click **Add secret**.

After adding the secret, re-run the failed CI job. It should now be able to authenticate and push to the Cachix cache successfully.

## Common Issues

### 1. Template Not Found

```nix
# Error: 'template-name' not in enumeration
services.nix-mox.templates.templates = [
  "template-name"  # Check spelling
];
```

### 2. Dependency Errors

```nix
# Error: Dependency 'some-package' not found
services.nix-mox.templates.customOptions = {
  template-name = {
    package = "some-package";  # Verify in pkgs
  };
};
```

### 3. Variable Substitution

```nix
# Error: @variable@ not replaced
services.nix-mox.templates.templateVariables = {
  variable = "value";  # Match exactly
};
```

### 4. Override Issues

```nix
# Error: Override not applied
services.nix-mox.templates.templateOverrides = {
  "template-name" = ./path;  # Verify structure
};
```

### 5. Service Failures

```bash
# Check service status
systemctl status <service-name>.service
journalctl -u <service-name>.service
```

## Debug Steps

1. Check Configuration
   - Verify template names
   - Validate variables
   - Check custom options

2. Verify Files
   - Check file structure
   - Verify permissions
   - Test file paths

3. Test Services
   - Run manually
   - Check status
   - Review logs

4. Monitor
   - Watch service status
   - Check error logs
   - Verify changes

## Gaming Troubleshooting

### 1. GPU Passthrough Issues

```bash
# Check GPU passthrough status
lspci -k | grep -A 2 -E "(VGA|3D)"

# Verify IOMMU groups
find /sys/kernel/iommu_groups/ -type l

# Check for VFIO modules
lsmod | grep vfio
```

### 2. Game Performance Issues

```bash
# Check GPU usage
nvidia-smi

# Monitor CPU and memory
htop

# Check disk I/O
iostat -x 1
```

### 3. Steam/Rust Update Failures

```bash
# Check Steam logs
cat ~/.steam/steam/logs/content_log.txt

# Verify Rust installation
ls -la ~/.steam/steam/steamapps/common/Rust
```

### 4. Game Mode Configuration

```bash
# Verify Game Mode settings
reg query "HKLM\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode"

# Check fullscreen optimizations
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "C:\Program Files (x86)\Steam\steamapps\common\Rust\RustClient.exe"
```
