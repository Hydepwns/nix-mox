# GitHub Workflows

This directory contains the GitHub Actions workflows for nix-mox.

## Workflows

### `ci.yml` - Main CI Pipeline

The main continuous integration workflow that runs on every push and pull request.

**Features:**

- **Cross-platform testing** - Runs on Ubuntu and macOS
- **Package building** - Builds platform-specific packages
- **Comprehensive testing** - Runs unit, integration, storage, and performance tests
- **Coverage reporting** - Generates and uploads coverage reports to Codecov
- **Heavy package builds** - Builds heavy packages on main branch only
- **Release automation** - Creates releases on tags

**Jobs:**

1. **build-and-test** - Builds packages and runs tests on Ubuntu and macOS
2. **build-heavy-packages** - Builds heavy packages (only on main branch)
3. **release** - Creates GitHub releases (only on tags)

**Custom Actions Used:**

- `./.github/actions/setup-nix` - Sets up Nix with custom configuration
- `./.github/actions/run-tests` - Runs comprehensive tests with coverage

### `test-local.yml` - Local Testing Workflow

Manual workflow for running different types of tests locally.

**Features:**

- **Manual triggering** - Can be run manually with different test types
- **Test type selection** - Choose between basic, performance, cross-platform, or all tests
- **Coverage generation** - Generates coverage reports for analysis
- **Performance benchmarking** - Measures test execution times

**Test Types:**

- **basic** - Unit and integration tests
- **performance** - Performance benchmarks and timing tests
- **cross-platform** - Cross-platform compatibility tests
- **all** - All test types combined

### `release.yml` - Release Management

Handles release automation and deployment.

## Custom Actions

### `setup-nix`

Sets up Nix with custom configuration for nix-mox projects.

**Inputs:**

- `nix-version` (optional): Nix version to install (default: `2.19.2`)
- `extra-trusted-public-keys` (optional): Additional trusted public keys

### `run-tests`

Runs comprehensive tests for nix-mox with coverage reporting.

**Inputs:**

- `test-suites` (optional): Test suites to run (default: `unit,integration`)
- `verbose` (optional): Enable verbose output (default: `false`)
- `generate-coverage` (optional): Generate coverage report (default: `true`)

## Usage

### Running CI

The main CI workflow runs automatically on:

- Every push to `main`
- Every pull request to `main`

### Running Local Tests

1. Go to Actions tab in GitHub
2. Select "Test Local" workflow
3. Click "Run workflow"
4. Choose test type and run

### Creating Releases

1. Create and push a tag: `git tag v1.0.0 && git push origin v1.0.0`
2. The release workflow will automatically create a GitHub release

## Configuration

### Secrets Required

- `CACHIX_AUTH_TOKEN` - Cachix authentication token
- `CACHIX_SIGNING_KEY` - Cachix signing key
- `CODECOV_TOKEN` - Codecov token for coverage reporting

### Environment Variables

- `CI=true` - Set automatically in CI environment
- `TEST_TEMP_DIR=/tmp/nix-mox-tests` - Test output directory

## Troubleshooting

### Common Issues

1. **Tests failing** - Check the test logs for specific error messages
2. **Coverage not generated** - Verify `generate-coverage` is set to `true`
3. **Build failures** - Check package dependencies and Nix configuration
4. **Timeout issues** - Increase timeout values in workflow if needed

### Debugging

- Use `verbose: 'true'` in test actions for detailed output
- Check artifact uploads for test results and coverage reports
- Review Codecov dashboard for coverage analysis
