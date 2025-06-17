# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
