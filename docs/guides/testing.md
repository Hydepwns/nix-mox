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

## Test Structure

```
tests/
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
- Located in `tests/unit/`

### Integration Tests
- Test end-to-end functionality
- Platform-specific checks
- Real environment validation
- Located in `tests/integration/`

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

## Continuous Integration

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: nix flake check
```

### Local Development
```bash
# Run tests before commit
make test
git add .
git commit -m "feat: new feature with passing tests"
```

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

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure `TEST_TEMP_DIR` is writable
2. **OS Detection**: Use `sys host | get long_os_version` for accurate detection
3. **Coverage Reports**: Check `TEST_TEMP_DIR` for generated reports

### Debug Mode

```bash
# Enable debug output
$env.DEBUG = true
make test
```

For more detailed information, see [Testing Documentation](./../scripting/TESTING.md). 
