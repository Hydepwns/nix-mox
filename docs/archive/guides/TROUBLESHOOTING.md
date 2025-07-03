# Troubleshooting Guide

This guide provides solutions to common issues encountered while working with the `nix-mox` repository.

## Table of Contents

- [CI/CD Failures](#cicd-failures)
  - [Cachix Signature Verification Failed](#cachix-signature-verification-failed)
- [Common Issues](#common-issues)
- [Debug Steps](#debug-steps)
- [Gaming Troubleshooting](#gaming-troubleshooting)
- [CI/CD Pipeline Issues](#cicd-pipeline-issues)
- [Local Development Issues](#local-development-issues)
- [Performance Issues](#performance-issues)
- [Getting Help](#getting-help)
- [Debugging Tools](#debugging-tools)
- [Environment Variables](#environment-variables)
- [Display Troubleshooting](#display-troubleshooting)

---

## CI/CD Failures

### Cachix Signature Verification Failed

**Symptom:**

The CI job fails during the "Push to Cachix" or "Setup Cachix" step with an error similar to this:

```bash
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

```bash
# Error: 'template-name' not in enumeration
services.nix-mox.templates.templates = [
  "template-name"  # Check spelling
];
```

### 2. Dependency Errors

```bash
# Error: Dependency 'some-package' not found
services.nix-mox.templates.customOptions = {
  template-name = {
    package = "some-package";  # Verify in pkgs
  };
};
```

### 3. Variable Substitution

```bash
# Error: @variable@ not replaced
services.nix-mox.templates.templateVariables = {
  variable = "value";  # Match exactly
};
```

### 4. Override Issues

```bash
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

## Common Issues and Solutions

### CI/CD Pipeline Issues

#### Cachix Authentication Errors

**Problem**: CI pipeline fails with Cachix 401 Unauthorized errors:

```bash
Error: The process '/home/runner/.nix-profile/bin/cachix' failed with exit code 3
```

**Symptoms**:

- Build jobs fail during Cachix push operations
- Error messages mentioning "401 Unauthorized"
- Cachix daemon fails to authenticate

**Causes**:

1. Missing GitHub repository secrets
2. Expired or invalid Cachix tokens
3. Incorrect cache permissions
4. Malformed secret values

**Solutions**:

1. **Check GitHub Secrets**:
   - Go to your repository → Settings → Secrets and variables → Actions
   - Verify these secrets exist:
     - `CACHIX_AUTH_TOKEN`
     - `CACHIX_SIGNING_KEY`

2. **Regenerate Cachix Tokens**:

   ```bash
   # Run the setup script to get current credentials
   ./scripts/setup-cachix.nu
   ```

3. **Manual Token Generation**:
   - Visit [Cachix App](https://app.cachix.org/)
   - Log in to your account
   - Navigate to your `nix-mox` cache
   - Go to Settings → Auth Tokens
   - Generate a new auth token
   - Copy the signing key from cache settings

4. **Update GitHub Secrets**:
   - Replace the existing secrets with new values
   - Ensure no extra whitespace or newlines in the values
   - Test the secrets by triggering a new CI run

5. **Temporary Workaround**:
   If you need to get CI working immediately without Cachix:
   - The workflows are configured with `continue-on-error: true` for Cachix operations
   - CI will continue even if Cachix fails
   - You can temporarily remove the Cachix secrets to skip those operations entirely

**Prevention**:

- Regularly rotate Cachix tokens (every 90 days)
- Use the setup script to verify credentials
- Monitor CI logs for authentication warnings

#### Test Failures

**Problem**: Tests fail during CI execution

**Common Causes**:

- Missing dependencies
- Environment-specific issues
- Flaky tests
- Coverage threshold violations

**Solutions**:

1. Run tests locally first: `nix flake check`
2. Check test logs for specific error messages
3. Verify all dependencies are properly declared
4. Adjust coverage thresholds if needed

#### Build Timeouts

**Problem**: CI jobs timeout during package builds

**Solutions**:

1. Increase timeout values in workflow files
2. Use Cachix to cache build artifacts
3. Optimize build configurations
4. Split heavy builds into separate jobs

### Local Development Issues

#### Nix Environment Problems

**Problem**: `nix develop` fails or behaves unexpectedly

**Solutions**:

1. Update Nix: `nix-env -u nix`
2. Clear Nix store: `nix store gc`
3. Rebuild flake: `nix flake update`
4. Check flake.lock for conflicts

#### Script Execution Issues

**Problem**: Scripts fail to execute or produce unexpected results

**Solutions**:

1. Check script permissions: `chmod +x scripts/*.nu`
2. Verify Nushell installation: `which nu`
3. Run with debug output: `nu --debug scripts/script.nu`
4. Check script dependencies

### Performance Issues

#### Slow Builds

**Problem**: Builds take too long

**Solutions**:

1. Enable Cachix for build caching
2. Use parallel builds where possible
3. Optimize package dependencies
4. Consider using remote builders

#### Memory Issues

**Problem**: Out of memory errors during builds

**Solutions**:

1. Reduce parallel build cores: `NIX_BUILD_CORES=1`
2. Increase system memory
3. Use swap space
4. Optimize build configurations

### Getting Help

If you encounter issues not covered here:

1. **Check the logs**: Look for specific error messages
2. **Search existing issues**: Check GitHub issues for similar problems
3. **Create a minimal reproduction**: Isolate the problem
4. **Open an issue**: Provide detailed information including:
   - Error messages
   - Environment details
   - Steps to reproduce
   - Expected vs actual behavior

### Debugging Tools

Useful commands for debugging:

```bash
# Check Nix environment
nix --version
nix flake show

# Debug flake
nix flake check --verbose

# Check Cachix status
cachix whoami
cachix show nix-mox

# Run tests with debug output
nix flake check --verbose --impure

# Check system resources
nix show-config
```

### Environment Variables

Key environment variables for debugging:

- `NIX_BUILD_CORES`: Control parallel builds
- `NIX_DEBUG`: Enable debug output
- `NIX_VERBOSE`: Verbose logging
- `CACHIX_AUTH_TOKEN`: Cachix authentication
- `CACHIX_SIGNING_KEY`: Cachix signing key

## Display Troubleshooting
- Run `make display-test` before/after config changes
- If display fails: check output, follow recommendations
- Use backup config if needed
- For hardware/driver issues: rerun with `make display-test-verbose`
