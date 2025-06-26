# Coverage Quick Reference

## 🚀 Quick Start

```bash
# Run tests and generate coverage
make test && make coverage

# Check coverage files
ls -la coverage-tmp/
cat coverage-tmp/coverage-summary.json
```

## 📊 Coverage Commands

| Command | Description | Use Case |
|---------|-------------|----------|
| `make coverage` | LCOV format (Codecov compatible) | **Recommended for CI** |
| `make coverage-grcov` | Rust-based line coverage | Advanced Rust projects |
| `make coverage-tarpaulin` | Simplified Rust coverage | Easier Rust coverage |
| `make coverage-custom` | Test result tracking | Test pass/fail analysis |
| `make coverage-ci` | CI-optimized coverage | GitHub Actions |
| `make coverage-local` | Local development | With fallbacks |

## 🔧 Troubleshooting

### Codecov Shows 0% Coverage
```bash
# 1. Check if tests are running
make test

# 2. Generate coverage
make coverage

# 3. Verify LCOV file exists
ls -la coverage-tmp/coverage.lcov

# 4. Check file content
head -5 coverage-tmp/coverage.lcov
```

### No Coverage Files Generated
```bash
# 1. Check test results
ls -la coverage-tmp/nix-mox-tests/

# 2. Run tests first
make test

# 3. Generate coverage
make coverage
```

### Coverage Generation Fails
```bash
# 1. Check Nushell installation
which nu

# 2. Run with verbose output
nu scripts/tests/setup-coverage.nu --approach lcov --verbose

# 3. Check for errors in output
```

## 📁 File Locations

```
coverage-tmp/
├── coverage.lcov          # LCOV format (for Codecov)
├── coverage-summary.json  # Coverage summary
└── nix-mox-tests/        # Test result files
    ├── test_result_*.json
    └── ...
```

## 🔗 Related Documentation

- [Full Coverage Guide](COVERAGE.md)
- [CI/CD Setup](../.github/workflows/ci.yml)
- [Test Documentation](../scripts/tests/README.md)

## 💡 Tips

- **Always run tests first**: `make test` before `make coverage`
- **Use LCOV for Codecov**: Most reliable format for CI
- **Check CI logs**: Look for coverage generation errors
- **Local testing**: Use `make coverage-local` for development
- **Fallback coverage**: System generates minimal coverage if tests fail 