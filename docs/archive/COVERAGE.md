# Coverage & CI Guide

## Quick Start

- Run all tests: `make test`
- Run with coverage: `make coverage`
- Coverage output: `coverage-tmp/coverage.lcov` (Codecov-compatible)
- See CI status and coverage: [Codecov](https://codecov.io/gh/Hydepwns/nix-mox)

## Coverage Approaches

- **LCOV** (default, recommended for Codecov)
- **grcov** (Rust, advanced)
- **tarpaulin** (Rust, simple)
- **Custom** (test result summaries)

Switch approach: `make coverage-grcov`, `make coverage-tarpaulin`, or `make coverage-custom`

## CI/CD Features

- Multi-platform: Linux & macOS
- Automated tests: unit, integration, storage, performance
- Coverage: LCOV, Codecov integration
- Caching: Cachix for faster builds
- Security & performance checks

## Troubleshooting

- See [Coverage Quick Reference](COVERAGE-QUICK-REFERENCE.md) for commands and troubleshooting tips.
- Check CI logs and `coverage-tmp/coverage.lcov` for errors.

---

For full details, see the [README](../README.md) or explore the scripts in `scripts/tests/`. 