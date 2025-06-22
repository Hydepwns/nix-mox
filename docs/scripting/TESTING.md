# Testing Guide

Comprehensive guide for testing nix-mox scripts and ensuring code quality through automated testing.

## Overview

nix-mox implements a robust testing framework that provides:

- Unit testing for individual functions
- Integration testing for end-to-end workflows
- Coverage reporting and analysis
- Automated test execution
- Cross-platform testing support

## Test Structure

```bash
scripts/tests/
├── unit/           # Unit tests
│   ├── config_validation.nu
│   ├── logging_tests.nu
│   ├── platform_detection.nu
│   └── error_handling.nu
├── integration/    # Integration tests
│   ├── proxmox_update_tests.nu
│   ├── backup_tests.nu
│   ├── zfs_tests.nu
│   └── performance_tests.nu
├── lib/           # Test utilities
│   ├── test-utils.nu    # Core test utilities (includes track_test)
│   ├── test-coverage.nu # Coverage reporting (includes aggregate_coverage)
│   ├── shared.nu        # Shared test functions
│   └── test-common.nu   # Common test functions
└── run-tests.nu   # Main test runner (includes setup_test_env, cleanup_test_env)
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
nu -c "source scripts/tests/run-tests.nu; run []"

# Run specific test types
nu scripts/tests/unit/unit-tests.nu
nu scripts/tests/integration/integration-tests.nu
```

### Using CI Scripts

```bash
# Run quick CI test locally
make ci-test

# Run comprehensive CI test locally
make ci-local
```

## Writing Tests

### Basic Test Structure

```nushell
#!/usr/bin/env nu

# Import test utilities (no longer need to import coverage-core.nu separately)
use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *

def main [] {
    print "Running tests..."
    
    # Track test results (now available from test-utils.nu)
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
assert_true $condition "Message"
assert_false $condition "Message"
assert_not_empty $value "Message"

# Test tracking
track_test "test_name" "category" "status" $duration

# Coverage reporting
generate_coverage_report
export_coverage_report "json"
```

### Advanced Test Patterns

```nushell
# Test with setup and teardown
def test_with_setup [test_name: string, setup: closure, test: closure, teardown: closure] {
    setup_test_env
    
    try {
        # Setup
        do $setup
        
        # Test
        do $test
        
        track_test $test_name "unit" "passed" 0.1
    } catch {
        track_test $test_name "unit" "failed" 0.1
        throw $env.LAST_ERROR
    } finally {
        # Teardown
        do $teardown
        cleanup_test_env
    }
}

# Mock external dependencies
def mock_command [command: string, output: string] {
    # Implementation for mocking external commands
}

# Test error conditions
def test_error_condition [test_name: string, error_operation: closure] {
    try {
        do $error_operation
        track_test $test_name "unit" "failed" 0.1
        throw "Expected error but operation succeeded"
    } catch {
        track_test $test_name "unit" "passed" 0.1
    }
}
```

## Test Categories

### Unit Tests (`scripts/tests/unit/`)

Unit tests focus on testing individual components in isolation:

#### Configuration Validation Tests

```nushell
def test_config_validation_device [] {
    setup_test_env
    
    try {
        let valid_config = { device = "test-device" }
        let result = (validate_device_config $valid_config)
        assert_true $result "Valid device config should pass validation"
        
        let invalid_config = { device = "" }
        let result = (validate_device_config $invalid_config)
        assert_false $result "Invalid device config should fail validation"
        
        track_test "config_validation_device" "unit" "passed" 0.1
        cleanup_test_env
        true
    } catch {
        track_test "config_validation_device" "unit" "failed" 0.1
        cleanup_test_env
        false
    }
}
```

#### Logging Tests

```nushell
def test_logging_functions [] {
    setup_test_env
    
    try {
        let test_log = "/tmp/test.log"
        
        # Test info logging
        log_info "Test message" $test_log
        let log_content = (open $test_log | str contains "INFO")
        assert_true $log_content "Log should contain INFO level"
        
        # Test error logging
        log_error "Test error" $test_log
        let log_content = (open $test_log | str contains "ERROR")
        assert_true $log_content "Log should contain ERROR level"
        
        track_test "logging_functions" "unit" "passed" 0.1
        cleanup_test_env
        true
    } catch {
        track_test "logging_functions" "unit" "failed" 0.1
        cleanup_test_env
        false
    }
}
```

#### Platform Detection Tests

```nushell
def test_platform_detection [] {
    setup_test_env
    
    try {
        let platform = (detect_platform)
        assert_not_empty $platform "Platform detection should return a value"
        
        # Test platform-specific logic
        if $platform == "linux" {
            assert_true (check_linux_tools) "Linux tools should be available"
        }
        
        track_test "platform_detection" "unit" "passed" 0.1
        cleanup_test_env
        true
    } catch {
        track_test "platform_detection" "unit" "failed" 0.1
        cleanup_test_env
        false
    }
}
```

### Integration Tests (`scripts/tests/integration/`)

Integration tests focus on testing complete workflows and system interactions:

#### Proxmox Update Tests

```nushell
def test_proxmox_update_workflow [] {
    setup_test_env
    
    try {
        # Test dry-run mode
        let result = (run_proxmox_update --dry-run)
        assert_true $result "Proxmox update dry-run should succeed"
        
        # Test error handling
        let result = (run_proxmox_update --invalid-option)
        assert_false $result "Invalid options should fail"
        
        track_test "proxmox_update_workflow" "integration" "passed" 1.0
        cleanup_test_env
        true
    } catch {
        track_test "proxmox_update_workflow" "integration" "failed" 1.0
        cleanup_test_env
        false
    }
}
```

#### Backup Tests

```nushell
def test_backup_workflow [] {
    setup_test_env
    
    try {
        # Test backup creation
        let result = (create_test_backup)
        assert_true $result "Backup creation should succeed"
        
        # Test backup verification
        let result = (verify_backup_integrity)
        assert_true $result "Backup integrity should be verified"
        
        track_test "backup_workflow" "integration" "passed" 2.0
        cleanup_test_env
        true
    } catch {
        track_test "backup_workflow" "integration" "failed" 2.0
        cleanup_test_env
        false
    }
}
```

#### ZFS Tests

```nushell
def test_zfs_operations [] {
    setup_test_env
    
    try {
        # Test snapshot creation
        let result = (create_test_snapshot)
        assert_true $result "Snapshot creation should succeed"
        
        # Test snapshot pruning
        let result = (prune_old_snapshots)
        assert_true $result "Snapshot pruning should succeed"
        
        track_test "zfs_operations" "integration" "passed" 1.5
        cleanup_test_env
        true
    } catch {
        track_test "zfs_operations" "integration" "failed" 1.5
        cleanup_test_env
        false
    }
}
```

#### Performance Tests

```nushell
def test_performance_metrics [] {
    setup_test_env
    
    try {
        let start_time = (date now)
        
        # Run performance test
        let result = (run_performance_test)
        
        let end_time = (date now)
        let duration = (($end_time - $start_time) | into float)
        
        # Assert performance requirements
        assert_true ($duration < 30.0) "Performance test should complete within 30 seconds"
        assert_true $result "Performance test should succeed"
        
        track_test "performance_metrics" "integration" "passed" $duration
        cleanup_test_env
        true
    } catch {
        track_test "performance_metrics" "integration" "failed" 0.1
        cleanup_test_env
        false
    }
}
```

## Coverage Reporting

### Coverage Structure

Tests automatically generate coverage reports in multiple formats:

```json
{
  "summary": {
    "total_tests": 12,
    "passed_tests": 10,
    "failed_tests": 0,
    "skipped_tests": 2,
    "test_duration": 5.044469643999997,
    "pass_rate": 83.33333333333334
  },
  "categories": {
    "integration": 2,
    "unit": 10
  },
  "results": [
    {
      "name": "config_validation_device",
      "category": "unit",
      "status": "passed",
      "duration": 0.1,
      "timestamp": 1750367865383296746
    }
  ]
}
```

### Coverage Analysis

```bash
# View coverage report
cat coverage-tmp/nix-mox-tests/coverage.json

# Check coverage in CI
nix develop --command nu -c "
  let coverage = (open coverage-tmp/nix-mox-tests/coverage.json | from json)
  let pass_rate = ($coverage | get summary.pass_rate)
  if $pass_rate < 90 {
    error make { msg: 'Test coverage below 90%' }
  }
"
```

## Best Practices

### 1. Test Organization

- Use descriptive test names that explain the scenario
- Group related tests together
- Follow the Arrange-Act-Assert pattern
- Keep tests focused and single-purpose

### 2. Environment Management

- Always use `setup_test_env` and `cleanup_test_env`
- Use `TEST_TEMP_DIR` for temporary files
- Clean up after tests to avoid interference
- Mock external dependencies when possible

### 3. Platform Detection

- Use `sys host | get long_os_version` for OS detection
- Skip platform-specific tests appropriately
- Test cross-platform compatibility
- Handle platform-specific edge cases

### 4. Error Handling

- Test both success and failure scenarios
- Verify error messages and codes
- Test edge cases and boundary conditions
- Include proper cleanup in error scenarios

### 5. Performance Testing

- Set reasonable timeouts
- Test with realistic data sizes
- Monitor resource usage
- Benchmark critical paths

### 6. Test Data Management

- Use fixtures for consistent test data
- Avoid hardcoded test values
- Generate test data programmatically
- Clean up test data after use

## Continuous Integration

### GitHub Actions

The project includes comprehensive CI/CD with automated testing:

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        nix-channel: [nixos-unstable]

    steps:
    - uses: actions/checkout@v4
    - name: Install Nix
      uses: DeterminateSystems/nix-installer-action@main
    - name: Setup Nix cache
      uses: DeterminateSystems/magic-nix-cache-action@main
    - name: Run tests
      run: nix flake check
    - name: Upload coverage report
      uses: actions/upload-artifact@v4
      with:
        name: coverage-report
        path: coverage-tmp/nix-mox-tests/coverage.json
        if-no-files-found: ignore
    - name: Check test coverage
      run: |
        nix develop --command nu -c "
          let coverage = (open coverage-tmp/nix-mox-tests/coverage.json | from json)
          let pass_rate = ($coverage | get summary.pass_rate)
          if $pass_rate < 90 {
            error make { msg: 'Test coverage below 90%' }
          }
        "
```

### Local Development

```bash
# Pre-commit testing
make test
make unit
make integration

# Coverage verification
make test
cat coverage-tmp/nix-mox-tests/coverage.json | jq '.summary.pass_rate'

# Performance testing
make ci-local
```

## Debugging Tests

### Common Issues

1. **Environment Problems**

   ```bash
   # Check test environment
   echo $TEST_TEMP_DIR
   ls -la coverage-tmp/
   ```

2. **Permission Issues**

   ```bash
   # Fix permissions
   chmod +x scripts/tests/*.nu
   chmod +x scripts/tests/unit/*.nu
   chmod +x scripts/tests/integration/*.nu
   ```

3. **Dependency Issues**

   ```bash
   # Check dependencies
   which nu
   which nix
   nix develop .#testing
   ```

### Debug Mode

```bash
# Enable debug mode
$env.DEBUG = true
make test

# Verbose output
make test 2>&1 | tee test.log
```

### Test Isolation

```bash
# Run single test
nu scripts/tests/unit/config_validation.nu

# Run with specific environment
TEST_TEMP_DIR=/tmp/custom-test nu scripts/tests/unit/config_validation.nu
```

## Future Enhancements

### Planned Testing Features

1. **Advanced Coverage**
   - Branch coverage analysis
   - Function coverage tracking
   - Performance regression testing

2. **Test Automation**
   - Automated test generation
   - Property-based testing
   - Mutation testing

3. **Enhanced Reporting**
   - HTML coverage reports
   - Test trend analysis
   - Performance benchmarking

4. **Cross-Platform Testing**
   - Windows test support
   - macOS optimization
   - Container-based testing

### Contributing to Tests

1. **Adding New Tests**
   - Follow established patterns
   - Include comprehensive coverage
   - Test edge cases
   - Update documentation

2. **Test Maintenance**
   - Keep tests up to date
   - Refactor when needed
   - Remove obsolete tests
   - Improve test performance

3. **Test Documentation**
   - Document test purpose
   - Explain test scenarios
   - Update test examples
   - Maintain test guides
