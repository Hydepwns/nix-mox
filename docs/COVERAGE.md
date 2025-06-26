# Code Coverage for nix-mox

> **Quick Reference**: See [Coverage Quick Reference](COVERAGE-QUICK-REFERENCE.md) for common commands and troubleshooting.

This document explains the different code coverage approaches available for nix-mox and how to use them with Codecov.

## Overview

nix-mox supports multiple coverage approaches to work with different tools and requirements:

1. **LCOV Coverage** (Recommended for Codecov)
2. **grcov Coverage** (Rust-based, advanced)
3. **tarpaulin Coverage** (Rust-based, easier)
4. **Custom Coverage** (Test-based, what you had before)

## Quick Start

### For Codecov (Recommended)

```bash
# Set up LCOV coverage (works with Codecov)
make coverage

# Or run directly
nu scripts/tests/setup-coverage.nu --approach lcov --verbose
```

### For Local Development

```bash
# Try grcov first, fallback to LCOV
make coverage-local

# Or run directly
nu scripts/tests/setup-coverage.nu --approach grcov --verbose
```

## Coverage Approaches

### 1. LCOV Coverage (Recommended)

**Best for**: Codecov integration, standard coverage format

**How it works**: Generates LCOV format coverage reports based on test execution

**Usage**:
```bash
make coverage
# or
nu scripts/tests/setup-coverage.nu --approach lcov --verbose
```

**Output**: `coverage-tmp/coverage.lcov` (Codecov-compatible)

### 2. grcov Coverage (Rust-based)

**Best for**: Advanced Rust projects, detailed coverage analysis

**Requirements**: Rust toolchain installed

**How it works**: Uses LLVM instrumentation to track line-by-line coverage

**Usage**:
```bash
make coverage-grcov
# or
nu scripts/tests/setup-coverage.nu --approach grcov --verbose
```

**Installation**:
```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# grcov will be installed automatically when needed
```

### 3. tarpaulin Coverage (Rust-based)

**Best for**: Easier Rust coverage, simpler setup

**Requirements**: Rust toolchain installed

**How it works**: Simplified Rust coverage tool

**Usage**:
```bash
make coverage-tarpaulin
# or
nu scripts/tests/setup-coverage.nu --approach tarpaulin --verbose
```

### 4. Custom Coverage (Test-based)

**Best for**: Test result tracking, not actual code coverage

**How it works**: Tracks test pass/fail rates, not line coverage

**Usage**:
```bash
make coverage-custom
# or
nu scripts/tests/setup-coverage.nu --approach custom --verbose
```

**Note**: This generates test result summaries, not code coverage that Codecov can understand.

## CI/CD Integration

### GitHub Actions

Your CI workflow is already configured to use LCOV coverage:

```yaml
- name: Upload to Codecov
  uses: codecov/codecov-action@v5
  with:
    files: coverage-tmp/coverage.lcov
    flags: unittests
    name: codecov-${{ matrix.os }}
    fail_ci_if_error: false
    verbose: true
    token: ${{ secrets.CODECOV_TOKEN }}
    directory: coverage-tmp/
```

### Local CI Testing

```bash
# Test coverage setup locally
make coverage-ci

# Run full CI test
make ci-local
```

## Troubleshooting

### Codecov Shows 0% Coverage

**Problem**: Codecov is receiving coverage files but showing 0% coverage.

**Solutions**:

1. **Use LCOV format** (recommended):
   ```bash
   make coverage
   ```

2. **Check coverage file format**:
   ```bash
   # Verify LCOV file exists and has content
   ls -la coverage-tmp/coverage.lcov
   head -10 coverage-tmp/coverage.lcov
   ```

3. **Verify Codecov token**:
   - Ensure `CODECOV_TOKEN` is set in your repository secrets
   - Check that the token is valid and has proper permissions

4. **Check CI logs**:
   - Look for coverage generation errors
   - Verify the coverage file is being uploaded

### No Coverage Files Generated

**Problem**: Coverage files are not being created.

**Solutions**:

1. **Check test execution**:
   ```bash
   make test
   ```

2. **Verify test result files**:
   ```bash
   ls -la coverage-tmp/nix-mox-tests/
   ```

3. **Run coverage setup manually**:
   ```bash
   nu scripts/tests/setup-coverage.nu --approach lcov --verbose
   ```

### Rust Coverage Issues

**Problem**: grcov or tarpaulin coverage fails.

**Solutions**:

1. **Install Rust**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source ~/.cargo/env
   ```

2. **Fallback to LCOV**:
   ```bash
   make coverage  # Uses LCOV instead
   ```

## File Structure

```
coverage-tmp/
├── coverage.lcov          # LCOV format (for Codecov)
├── coverage-summary.json  # Coverage summary
├── nix-mox-tests/        # Test result files
│   ├── test_result_*.json
│   └── ...
└── ...
```

## Configuration

### codecov.yml

Your `codecov.yml` is configured for LCOV format:

```yaml
parsers:
  gcov:
    branch_detection:
      conditional: yes
      loop: yes
      method: no
      macro: no
```

### Environment Variables

- `TEST_TEMP_DIR`: Directory for test results (default: `/tmp/nix-mox-tests`)
- `COVERAGE_DIR`: Directory for coverage reports (default: `coverage-tmp`)
- `CI`: Set to "true" in CI environments

## Best Practices

1. **Use LCOV for Codecov**: LCOV format is the most reliable for Codecov integration
2. **Test locally first**: Run coverage setup locally before pushing to CI
3. **Check file formats**: Ensure coverage files are in the correct format
4. **Monitor CI logs**: Watch for coverage generation errors in CI
5. **Use appropriate approach**: Choose the coverage approach that fits your needs

## Migration from Custom Coverage

If you were using the custom coverage approach before:

1. **Switch to LCOV**:
   ```bash
   make coverage
   ```

2. **Update CI workflow** (already done):
   - Uses `coverage-tmp/coverage.lcov` instead of `coverage-tmp/codecov.json`

3. **Verify Codecov integration**:
   - Check that Codecov receives the LCOV file
   - Verify coverage percentages are displayed correctly

## Support

For issues with coverage setup:

1. Check the troubleshooting section above
2. Run with verbose output: `--verbose` flag
3. Check CI logs for specific error messages
4. Verify all dependencies are installed

## References

- [Codecov Documentation](https://docs.codecov.io/)
- [LCOV Format](https://github.com/linux-test-project/lcov)
- [grcov Documentation](https://github.com/mozilla/grcov)
- [tarpaulin Documentation](https://github.com/xd009642/tarpaulin) 