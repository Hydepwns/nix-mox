# Testing Guide

## Test Structure

```bash
tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── fixtures/       # Test fixtures
└── lib/           # Test utilities
    └── test-utils.nu
```

## Writing Tests

### Basic Test Structure

```nushell
#!/usr/bin/env nu

use ../lib/test-utils.nu *

export-env {
    $env.TEST_NAME = "test-name"
}

def test_something [] {
    setup_test_env
    
    try {
        let result = (do_something)
        assert_equal $expected $result "Test failed"
        cleanup_test_env
        true
    } catch {
        cleanup_test_env
        false
    }
}

test_something
```

### Assertions

```nushell
# Equality assertion
assert_equal $expected $actual "Message"

# Boolean assertions
assert_true $condition "Message"
assert_false $condition "Message"

# Error handling assertion
test_error_handling "error_type" "expected_output"
```

## Running Tests

```bash
# Run all tests
nu scripts/core/run-tests.nu

# Run specific tests
nu scripts/core/run-tests.nu unit
nu scripts/core/run-tests.nu integration

# Run with debug output
nu scripts/core/run-tests.nu --debug
```

## Test Examples

### Unit Test

```nushell
def test_platform_detection [] {
    # Test Linux detection
    $env.OS = "Linux"
    let platform = (detect_platform)
    assert_equal "linux" $platform "Linux platform detection failed"
    
    # Test macOS detection
    $env.OS = "Darwin"
    let platform = (detect_platform)
    assert_equal "darwin" $platform "macOS platform detection failed"
}
```

### Integration Test

```nushell
def test_install_script [] {
    setup_test_env
    
    try {
        let result = (nix-mox --script install --dry-run)
        assert_true $result "Installation test failed"
        cleanup_test_env
        true
    } catch {
        cleanup_test_env
        false
    }
}
```

## Best Practices

1. Test Organization
   - Keep tests focused
   - Use descriptive names
   - Group related tests
   - Follow Arrange-Act-Assert

2. Test Data
   - Use fixtures for setup
   - Clean up after tests
   - Use meaningful data
   - Avoid hard-coded values

3. Error Handling
   - Test error conditions
   - Verify error messages
   - Test recovery
   - Include cleanup

4. Performance
   - Keep tests fast
   - Use timeouts
   - Avoid unnecessary setup
   - Clean up resources

## Debugging Tests

### Enable Debug Mode

```nushell
# Set debug environment variable
$env.DEBUG = true

# Or use command-line flag
nu scripts/core/run-tests.nu --debug
```

### Test Retry Mechanism

```nushell
# Retry flaky tests
test_retry 3 1 {
    # Test implementation
} true
```

### Performance Testing

```nushell
# Test performance
test_performance {
    # Operation to test
} 1000  # Maximum duration in milliseconds
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
        run: nu scripts/core/run-tests.nu
```

### Local Development

```bash
# Run tests before commit
git add .
nu scripts/core/run-tests.nu
git commit -m "Passing tests"
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
