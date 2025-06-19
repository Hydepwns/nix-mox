# Testing Guide

## Test Structure

```bash
tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── lib/           # Test utilities and shared functions
│   ├── test-utils.nu    # Core test utilities
│   ├── test-coverage.nu # Coverage reporting
│   ├── coverage-core.nu # Coverage tracking
│   ├── shared.nu        # Shared test functions
│   └── test-common.nu   # Common test functions
└── run-tests.nu   # Main test runner
```

## Running Tests

### Using Make (Recommended)

```bash
# Run all tests
make test

# Run specific test types
make unit          # Unit tests only
make integration   # Integration tests only

# Clean up test artifacts
make clean
```

### Using Nix Flake (CI/CD)

```bash
# Run all checks
nix flake check

# Run specific checks
nix flake check .#unit        # Unit tests only
nix flake check .#integration # Integration tests only
nix flake check .#test-suite  # Full test suite
```

### Using Nushell Directly

```bash
# Enter testing shell
nix develop .#testing

# Run all tests
nu -c "source tests/run-tests.nu; run []"

# Run specific test types
nu tests/unit/unit-tests.nu
nu tests/integration/integration-tests.nu
```

## Writing Tests

### Basic Test Structure

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

### Test Utilities

```nushell
# Environment setup
setup_test_env
cleanup_test_env

# Assertions
assert_equal $expected $actual "Message"

# Test tracking
track_test "test_name" "category" "status" $duration

# Coverage reporting
generate_coverage_report
export_coverage_report "json"
```

## Test Categories

### Unit Tests (`tests/unit/`)
- Individual component testing
- Fast execution
- Isolated functionality
- Mock external dependencies

### Integration Tests (`tests/integration/`)
- End-to-end system testing
- Platform-specific checks
- Service interaction testing
- Real environment validation

## Coverage Reporting

Tests automatically generate coverage reports:

```bash
# Coverage report is generated in TEST_TEMP_DIR
make test
# Check coverage.json in coverage-tmp/nix-mox-tests/
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
   - Test cross-platform compatibility

4. **Error Handling**
   - Test error conditions
   - Verify error messages
   - Include proper cleanup

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

## Gaming Tests

### Game Performance Test

```nushell
def test_game_performance [] {
    setup_test_env
    
    try {
        let result = (optimize_game_performance)
        assert_true $result "Game performance optimization failed"
        cleanup_test_env
        true
    } catch {
        cleanup_test_env
        false
    }
}

test_game_performance
```

### Steam/Rust Update Test

```nushell
def test_steam_rust_update [] {
    setup_test_env
    
    try {
        let result = (update_steam_rust)
        assert_true $result "Steam/Rust update failed"
        cleanup_test_env
        true
    } catch {
        cleanup_test_env
        false
    }
}

test_steam_rust_update
```
