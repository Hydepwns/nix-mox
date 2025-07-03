# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.1] - 2025-07-03

### Added

- **CI Runner Test Utilities**: New test utilities for CI runner infrastructure
  - Added `test-utils.sh` with common testing utilities for CI runner tests
  - Enhanced test job queue, logging, retry mechanism, and parallel execution utilities
  - Improved test infrastructure for CI runner templates

### Changed

- **Nushell Formatting**: Added nufmt support for Nushell files
  - `.treefmt.toml` now includes a Nushell formatter using `nufmt`
  - `nufmt` added to devshell and flake fmt app for consistent Nushell formatting
  - All `.nu` files are now auto-formatted with `nufmt` via treefmt
- **Makefile Robustness**: All Makefile targets are now declared as `.PHONY`
  - Prevents accidental file/target conflicts and improves reliability

- **Code Quality**: Comprehensive code formatting and style improvements
  - Enhanced `.treefmt.toml` with `--external-sources` flag for better shellcheck linting
  - Improved shell script formatting across all scripts with consistent style
  - Standardized error handling and output formatting in installation scripts
  - Enhanced gaming scripts with better error handling and testing logic
- **Installation Scripts**: Improved installation and setup script reliability
  - Updated `install-nix.sh` with better formatting and error handling
  - Enhanced `nix-mox-uninstall.sh` with improved cleanup logic
  - Refactored remote builder setup and test scripts for better maintainability
- **Configuration Files**: Updated system configuration structure
  - Improved `host1-home.nix` configuration structure
  - Enhanced `server-extra.nix` modularity
  - Updated main NixOS configuration with better settings
- **Error Handling**: Enhanced error handling across modules and packages
  - Improved error handling utilities with better formatting and messages
  - Enhanced Linux package configuration
  - Updated safe-configuration setup script with better structure
  - Improved monitoring test fragments and Linux common scripts

### Fixed

- **Shell Script Formatting**: Consistent formatting across all shell scripts
- **Error Handling**: Better error messages and handling patterns
- **Test Infrastructure**: Improved CI test script reliability and formatting
- **Code Style**: Standardized indentation and formatting patterns

## [0.5.0] - 2025-01-27

### Added

- **Code Formatting Infrastructure**: Comprehensive code formatting setup with treefmt
  - Added `treefmt.nix` configuration for consistent code formatting across the project
  - Added `.treefmt.toml` with formatting rules for multiple languages
  - Added `docs/FORMATTING.md` with detailed formatting guidelines and best practices
  - Added `docs/DEVELOPMENT.md` with comprehensive development workflow documentation
- **Enhanced Flake Infrastructure**: Improved Nix flake with better error handling and platform support
  - Enhanced error handling with `safeImport` functions and fallback mechanisms
  - Improved platform detection and system-specific package filtering
  - Better development shell organization with platform-specific availability
  - Enhanced test suite integration with granular test execution
- **Development Tools**: New development utilities and improved build system
  - Added `fmt`, `test`, and `update` apps for common development tasks
  - Enhanced Makefile with improved build targets and formatting support
  - Better development shell organization with platform-specific tools

### Changed

- **Documentation**: Comprehensive documentation updates across the project
  - Updated `README.md` with improved project description and usage examples
  - Enhanced `QUICK_START.md` with better getting started instructions
  - Updated `docs/CONTRIBUTING.md` with detailed contribution guidelines
  - Updated `docs/USAGE.md` with comprehensive usage examples and best practices
- **Core Scripts**: Significant improvements to core utilities and scripts
  - Enhanced installation and uninstallation scripts with better error handling
  - Improved CI testing capabilities with better reporting and reliability
  - Updated remote builder setup and testing with enhanced functionality
  - Enhanced Linux utilities and size analysis tools
- **Gaming Development**: Improved gaming development environment
  - Enhanced League of Legends configuration and launching scripts
  - Improved gaming environment testing with better validation
  - Better integration with development shells
- **Modules and Templates**: Enhanced testing and error handling
  - Improved error handling utilities across modules
  - Enhanced CI runner test scripts (integration, performance, unit tests)
  - Updated safe-configuration setup and test scripts
  - Improved monitoring test fragments with better testing capabilities
- **Development Shells**: Better organization and platform-specific features
  - Improved shell organization with platform-specific availability
  - Enhanced development tools integration
  - Better NixOS configuration integration

### Fixed

- **Build System**: Improved build artifact management and error handling
- **Script Reliability**: Enhanced script execution consistency across platforms
- **Test Infrastructure**: Better test organization and execution reliability
- **Platform Compatibility**: Improved cross-platform support and detection

## [0.4.3] - 2025-01-27

### Fixed

- **CI Pipeline**: Resolved critical CI failures and improved reliability
  - Fixed Nushell syntax errors in coverage generation step
  - Resolved type conversion issues in test result processing
  - Fixed Nix configuration conflicts with proper option priorities
  - Corrected `builtins.getEnv` usage patterns for default values
- **Nix Configuration**: Resolved configuration conflicts and syntax issues
  - Added `lib.mkDefault` for conflicting options (timezone, kernelPackages)
  - Fixed `builtins.getEnv` syntax with proper default value patterns
  - Removed personal attribute from top-level config to avoid option conflicts
  - Imported lib in user.nix and hardware.nix for mkDefault usage
- **Build Artifacts**: Improved CI script to output build artifacts to tmp directory
  - Used `--out-link` flag for all nix build commands
  - Redirected result symlinks to `tmp/result-<name>` instead of project root
  - Prevents clutter in main directory from build outputs

### Changed

- **CI Scripts**: Updated CI test script to use proper output directories
- **Documentation**: Updated QUICK_START.md and README.md with current status
- **Test Infrastructure**: Improved test reliability and CI integration

### Added

- **CI Reliability**: Enhanced CI pipeline with better error handling and reporting
- **Build Organization**: Cleaner build artifact management in CI environments

## [0.4.2] - 2025-01-27

### Fixed

- **Test Import Issues**: Resolved circular import dependencies in test infrastructure
  - Removed circular imports between `test-utils.nu`, `test-coverage.nu`, and `coverage-core.nu`
  - Consolidated `track_test` function into `test-utils.nu`
  - Consolidated `aggregate_coverage` function into `test-coverage.nu`
  - Added `setup_test_env` and `cleanup_test_env` directly to `run-tests.nu`
- **Test Function Availability**: Fixed "Command not found" errors for test functions
- **Test Documentation**: Updated documentation to reflect new import structure
- **Test Reliability**: Improved test execution consistency and reduced import errors

### Changed

- **Import Structure**: Simplified test module imports to avoid circular dependencies
- **Function Locations**: Reorganized test functions for better maintainability
- **Documentation**: Updated testing guides with correct import patterns and troubleshooting information

## [0.4.1] - 2025-01-27

### Added

- **Test Results Achievement**: Achieved 98% test pass rate with 153 total tests
- **Comprehensive Coverage**: Full coverage across argparse, platform, exec, and proxmox modules
- **Platform-Aware Testing**: Intelligent test skipping for unsupported platforms (ZFS on macOS)

### Changed

- **Documentation Updates**: Updated README and testing documentation with current test status
- **Test Performance**: Optimized test execution to ~17 seconds for full test suite

### Fixed

- **Platform Detection**: Improved macOS platform detection in tests
- **Test Reliability**: Enhanced test stability and consistency across platforms

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
