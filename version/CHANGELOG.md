# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-01-27

### Added

- **New Testing Infrastructure**: Comprehensive test suite with unit, integration, and performance tests
- **Make Commands**: `make test`, `make unit`, `make integration`, `make clean` for easy test execution
- **Nix Flake Integration**: Granular test execution via `nix flake check` with separate unit, integration, and full suite checks
- **Coverage Reporting**: Automatic test coverage generation with detailed reporting
- **Cross-platform Support**: Tests run on Linux, macOS, and Windows with proper OS detection
- **Sandbox Compatibility**: Test infrastructure works in Nix build environments
- **Common Script Utilities**: `modules/scripts/linux/common.nu` with shared logging and platform detection
- **Comprehensive Documentation**: Complete testing guide and updated architecture documentation

### Changed

- **Test Organization**: Moved tests from `modules/scripts/testing/` to top-level `tests/` directory
- **Test Structure**: Reorganized with `tests/unit/`, `tests/integration/`, and `tests/lib/` for better maintainability
- **OS Detection**: Fixed integration tests to use `sys host | get long_os_version` for accurate Linux detection
- **Environment Management**: Improved TMPDIR handling for Nix sandbox compatibility
- **Coverage Paths**: Updated coverage reports to use `TEST_TEMP_DIR` for sandbox compatibility
- **Documentation**: Complete rewrite of testing documentation with new commands and examples

### Fixed

- **Permission Errors**: Resolved sandbox permission issues by using writable temp directories
- **OS Detection**: Fixed integration tests to properly identify Linux systems and run monitoring tests
- **Test Execution**: Ensured tests work consistently across platforms and in CI environments
- **Import Paths**: Resolved circular imports and updated test file references
- **Duplicate Tests**: Consolidated duplicate integration test files from root level

### Removed

- **Duplicate Files**: Removed redundant integration test files from root `integration/` directory
- **Legacy Test Structure**: Cleaned up old test organization under `modules/scripts/testing/`

## [0.3.0] - 2025-06-17

### Added

- Comprehensive test infrastructure under `modules/scripts/testing/`
- New test organization with dedicated directories for fixtures, integration, and unit tests
- Enhanced test utilities and helpers
- Performance testing framework

### Changed

- Moved test infrastructure from root `tests/` to `modules/scripts/testing/`
- Reorganized test files for better maintainability
- Updated documentation to reflect new test structure
- Improved test execution and reporting

### Fixed

- Test path resolution in development shells
- Test execution consistency across platforms
- Documentation accuracy for test infrastructure

## [0.2.0] - 2025-06-15

### Added

- Modular package structure
- Improved documentation
- Development shell with common tools
- Windows automation scripts
- Linux system management scripts

### Changed

- Reorganized project structure
- Improved error handling
- Enhanced test coverage

### Fixed

- Platform-specific package handling
- Script path resolution
- Test execution on different platforms

## [0.1.0] - 2025-06-15

### Added

- Initial release
- Basic NixOS module
- Proxmox update script
- ZFS snapshot management
- Windows gaming automation
