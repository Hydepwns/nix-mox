# Testing Guide

## Overview

nix-mox includes a comprehensive testing framework with unit tests, integration tests, and coverage reporting. Tests are written in Nushell and can be run via Make commands or Nix flake checks.

## Quick Start

```bash
# Run all tests
make test

# Run specific test types
make unit          # Unit tests only
make integration   # Integration tests only

# Run via Nix flake (CI/CD)
nix flake check
```

## Available Make Targets

The project provides several convenient Make targets for testing:

### Testing Targets

- **`make test`** - Run all tests with coverage reporting
- **`make unit`** - Run unit tests only
- **`make integration`** - Run integration tests only
- **`make clean`** - Clean up test artifacts

### CI/CD Targets

- **`make ci-test`** - Run quick CI test locally
- **`make ci-local`** - Run comprehensive CI test locally

### Development Targets

- **`make build`** - Build default package
- **`make build-all`** - Build all packages
- **`make check`** - Run nix flake check
- **`make format`** - Format Nix files

### Maintenance Targets

- **`make clean-all`** - Clean all artifacts and temporary files
- **`make update`** - Update flake inputs
- **`make lock`** - Update flake.lock

For a complete list of available targets, run:

```bash
make help
```

## Test Structure

```bash
scripts/tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── lib/           # Test utilities
└── run-tests.nu   # Main test runner
```

## Test Categories

### Unit Tests

- Test individual components in isolation
- Fast execution
- Mock external dependencies
- Located in `scripts/tests/unit/`

### Integration Tests

- Test end-to-end functionality
- Platform-specific checks
- Real environment validation
- Located in `scripts/tests/integration/`

## Writing Tests

### Basic Test Template

```nushell
#!/usr/bin/env nu

use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *
use ../lib/coverage-core.nu *

def main [] {
    print "Running tests..."
    
    # Track test results
    track_test "test_name" "unit" "passed" 0.1
    
    # Your test logic here
    assert_equal $expected $actual "Test message"
    
    print "Tests completed successfully"
}

if ($env.NU_TEST? == "true") {
    main
}
main
```

## Test Utilities

### Environment Management

```nushell
setup_test_env      # Set up test environment
cleanup_test_env    # Clean up after tests
```

### Assertions

```nushell
assert_equal $expected $actual "Message"
```

### Test Tracking

```nushell
track_test "test_name" "category" "status" $duration
```

## Coverage Reporting

Tests automatically generate coverage reports in `TEST_TEMP_DIR`:

```bash
make test
# Check coverage.json in coverage-tmp/nix-mox-tests/
```

## Development Workflow

### Local Development

```bash
# 1. Enter development environment
make dev

# 2. Run tests before making changes
make test

# 3. Make your changes

# 4. Run tests again
make test

# 5. Format code
make format

# 6. Run full validation
make check

# 7. Commit changes
git add .
git commit -m "feat: your feature with passing tests"
```

### Pre-commit Checklist

Before committing your changes:

1. **Run tests**: `make test`
2. **Format code**: `make format`
3. **Check flake**: `make check`
4. **Build packages**: `make build-all` (optional)
5. **Clean artifacts**: `make clean`

### CI Testing Locally

Test the CI workflow locally before pushing:

```bash
# Quick CI test (recommended for development)
make ci-test

# Comprehensive CI test (simulates full GitHub Actions)
make ci-local

# Test specific CI components
./scripts/test-ci-local.sh build    # Only build packages
./scripts/test-ci-local.sh test     # Only run tests
./scripts/test-ci-local.sh checks   # Only run validation checks
./scripts/test-ci-local.sh clean    # Clean up artifacts
```

## Continuous Integration

### GitHub Actions

nix-mox uses GitHub Actions for continuous integration with the following workflow:

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
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

  test:
    needs: [build_packages]
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
        run: nix flake check --accept-flake-config --impure
```

**Key Features:**

- **Multi-platform builds**: Tests on both `x86_64-linux` and `aarch64-linux`
- **Multiple Nix versions**: Ensures compatibility with Nix 2.19.2 and 2.20.1
- **Package building**: Builds all available packages (`proxmox-update`, `vzdump-backup`, `zfs-snapshot`, `nixos-flake-update`)
- **Integrated testing**: Uses `nix flake check` to run the integrated test suite
- **Caching**: Leverages Cachix for faster builds and Nix store caching

## Best Practices

1. **Test Organization**
   - Use descriptive test names
   - Group related tests
   - Follow Arrange-Act-Assert pattern

2. **Environment Management**
   - Always use `setup_test_env` and `cleanup_test_env`
   - Use `TEST_TEMP_DIR` for temporary files
   - Clean up after tests

3. **Platform Detection**
   - Use `sys host | get long_os_version` for OS detection
   - Skip platform-specific tests appropriately

4. **Error Handling**
   - Test error conditions
   - Verify error messages
   - Include proper cleanup

5. **Development Workflow**
   - Run tests frequently during development
   - Use `make ci-test` for quick validation
   - Use `make ci-local` before pushing to GitHub
   - Keep test artifacts clean with `make clean`

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure `TEST_TEMP_DIR` is writable
2. **OS Detection**: Use `sys host | get long_os_version` for accurate detection
3. **Coverage Reports**: Check `TEST_TEMP_DIR` for generated reports
4. **Build Failures**: Run `make build-all` to identify package-specific issues

### Debug Mode

```bash
# Enable debug output
$env.DEBUG = true
make test
```

### Clean Start

If you encounter persistent issues:

```bash
# Clean everything and start fresh
make clean-all
make test
```

For more detailed information, see [Testing Documentation](./../scripting/TESTING.md).
