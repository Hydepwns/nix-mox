# CI/CD Guide

## Overview

nix-mox uses GitHub Actions for continuous integration and deployment. The CI/CD pipeline ensures code quality, tests compatibility across multiple platforms, and automates the release process.

## Workflow Structure

### Main CI Workflow (`.github/workflows/ci.yml`)

The main CI workflow consists of three jobs:

1. **build_packages**: Builds all packages on multiple platforms
2. **test**: Runs the integrated test suite
3. **release**: Creates GitHub releases (triggered by tags)

## Build Process

### Package Building

The `build_packages` job builds all available packages:

```yaml
build_packages:
  runs-on: ubuntu-latest
  strategy:
    matrix:
      system: [x86_64-linux, aarch64-linux]
      nix-version: ['2.19.2', '2.20.1']
  steps:
    - name: Build all packages
      run: |
        nix build .#proxmox-update .#vzdump-backup .#zfs-snapshot .#nixos-flake-update --system ${{ matrix.system }} --accept-flake-config
```

**Available Packages:**

- `proxmox-update`: Update and upgrade Proxmox host packages safely
- `vzdump-backup`: Backup Proxmox VMs and containers using vzdump
- `zfs-snapshot`: Create and manage ZFS snapshots with automatic pruning
- `nixos-flake-update`: Update NixOS flake inputs and system

**Build Matrix:**

- **Platforms**: `x86_64-linux`, `aarch64-linux`
- **Nix Versions**: `2.19.2`, `2.20.1`
- **Total Combinations**: 4 builds per commit

### Caching Strategy

The workflow uses multiple caching layers for optimal performance:

```yaml
- name: Setup Cachix
  uses: cachix/cachix-action@v16
  with:
    name: nix-mox
    signingKey: '${{ secrets.CACHIX_SIGNING_KEY }}'

- name: Cache Nix store
  uses: actions/cache@v4
  with:
    path: |
      /nix/store
      ~/.cache/nix
    key: nix-store-${{ runner.os }}-${{ matrix.nix-version }}-${{ hashFiles('**/*.nix') }}
    restore-keys: |
      nix-store-${{ runner.os }}-${{ matrix.nix-version }}-
```

## Testing Strategy

### Integrated Testing

The `test` job runs the integrated test suite:

```yaml
test:
  needs: [build_packages]
  runs-on: ubuntu-latest
  steps:
    - name: Run tests
      run: nix flake check --accept-flake-config --impure
```

**Test Categories:**

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test end-to-end functionality
- **Full Test Suite**: Complete test coverage

### Test Execution

Tests are executed using the Nix flake check system:

```bash
# Run all tests
nix flake check

# Run specific test categories
nix flake check .#unit        # Unit tests only
nix flake check .#integration # Integration tests only
nix flake check .#test-suite  # Full test suite
```

## Release Process

### Automated Releases

The `release` job creates GitHub releases when tags are pushed:

```yaml
release:
  if: startsWith(github.ref, 'refs/tags/')
  needs: [build_packages, test]
  runs-on: ubuntu-latest
  steps:
    - name: Create Release
      uses: softprops/action-gh-release@v2
      with:
        files: |
          result-*
        generate_release_notes: true
```

**Release Triggers:**

- Pushing a tag (e.g., `v1.0.0`)
- Requires both build and test jobs to pass

**Release Artifacts:**

- All built packages for supported platforms
- Automatically generated release notes

## Local Development

### Pre-commit Testing

Before submitting changes, run the full test suite locally:

```bash
# Build all packages
nix build .#proxmox-update .#vzdump-backup .#zfs-snapshot .#nixos-flake-update

# Run all tests
nix flake check

# Or use Make commands
make test
```

### CI Simulation

To simulate the CI environment locally:

```bash
# Build for specific system
nix build .#proxmox-update --system aarch64-linux

# Run tests with flake config acceptance
nix flake check --accept-flake-config --impure
```

## Configuration

### Flake Configuration

The workflow uses `--accept-flake-config` to handle flake configuration settings:

```nix
nixConfig = {
  extra-substituters = [
    "https://hydepwns.cachix.org"
    "https://nix-mox.cachix.org"
    "https://cache.nixos.org"
  ];
  extra-trusted-public-keys = [
    "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU="
    "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
};
```

### Environment Variables

Required secrets for the workflow:

- `CACHIX_SIGNING_KEY`: Signing key for Cachix cache
- `GITHUB_TOKEN`: GitHub token for releases (automatically provided)

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check if all packages exist in the flake
   - Verify system compatibility
   - Ensure Nix version compatibility

2. **Test Failures**
   - Run tests locally to reproduce issues
   - Check test environment setup
   - Verify test dependencies

3. **Cache Issues**
   - Clear GitHub Actions cache if needed
   - Check Cachix configuration
   - Verify signing key permissions

### Debug Mode

Enable debug output for troubleshooting:

```bash
# Enable Nix debug output
export NIX_DEBUG=1

# Run with verbose output
nix build .#proxmox-update --verbose
```

## Best Practices

1. **Pre-commit Testing**
   - Always run tests locally before pushing
   - Build packages to ensure they work
   - Check for linting issues

2. **Commit Messages**
   - Use conventional commit format
   - Include relevant issue numbers
   - Describe changes clearly

3. **Branch Strategy**
   - Use feature branches for development
   - Keep main branch stable
   - Require CI to pass before merging

4. **Release Management**
   - Use semantic versioning
   - Create detailed release notes
   - Test releases before publishing

## Related Documentation

- [Testing Guide](./testing.md) - Detailed testing information
- [Contributing Guide](../CONTRIBUTING.md) - Development guidelines
- [Package Documentation](../packages/README.md) - Package information
