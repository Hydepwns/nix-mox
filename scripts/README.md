# Scripts Directory

This directory contains utility scripts for development and CI testing.

## CI Testing Scripts

### `ci-test.sh` - Simple CI Testing

A quick and simple script to test the CI workflow locally.

**Usage:**

```bash
./scripts/ci-test.sh
```

**What it tests:**

- Package builds for current system
- Flake check
- Unit tests
- Integration tests
- Flake outputs validation
- Devshell validation

### `test-ci-local.sh` - Comprehensive CI Testing

A comprehensive script that simulates the full GitHub Actions workflow locally.

**Usage:**

```bash
# Run all CI jobs
./scripts/test-ci-local.sh

# Run specific jobs
./scripts/test-ci-local.sh build    # Only build packages
./scripts/test-ci-local.sh test     # Only run tests
./scripts/test-ci-local.sh checks   # Only run checks
./scripts/test-ci-local.sh clean    # Clean up artifacts
./scripts/test-ci-local.sh help     # Show help
```

**What it tests:**

- Package builds for multiple systems (x86_64-linux, aarch64-linux)
- Multiple Nix versions (2.19.2, 2.20.1)
- Full test suite (unit, integration, flake check)
- Release job simulation
- Comprehensive validation checks

## When to Use Which Script

- **Use `ci-test.sh`** for quick local testing during development
- **Use `test-ci-local.sh`** for comprehensive testing before pushing to GitHub
- **Use `test-ci-local.sh build`** to test only package builds
- **Use `test-ci-local.sh test`** to test only the test suite

## Prerequisites

Both scripts require:

- Nix installed and configured
- Running from the project root directory
- Proper permissions to execute the scripts

## Troubleshooting

If you encounter issues:

1. Make sure you're running from the project root
2. Ensure Nix is properly installed and configured
3. Check that all dependencies are available
4. Run `./scripts/test-ci-local.sh clean` to clean up any artifacts
