# nix-mox Scripts

This directory contains all platform-specific and automation scripts for the nix-mox toolkit, organized by functionality for better maintainability and discoverability.

## Directory Structure

```bash
scripts/
├── storage/           # Storage safety and configuration tools
│   ├── storage-guard.nu          # Pre-reboot storage validation
│   └── fix-storage-config.nu     # Auto-fix storage issues
├── maintenance/       # System maintenance and health tools
│   ├── health-check.nu           # System health validation
│   ├── cleanup.nu                # Project cleanup
│   ├── safe-rebuild.nu           # Safe system rebuild
│   ├── integrate-modules.nu      # Module integration
│   └── ci/                       # CI/CD tools
├── analysis/          # Analysis and reporting tools
│   ├── analyze-sizes.nu          # Package size analysis
│   ├── analyze-sizes.sh          # Shell version of size analysis
│   ├── advanced-cache.nu         # Cache optimization
│   ├── generate-docs.nu          # Documentation generation
│   ├── generate-sbom.nu          # Software bill of materials
│   ├── dashboard.nu              # Main dashboard (modular)
│   ├── modules/                  # Dashboard modules
│   │   ├── system.nu            # System monitoring
│   │   └── display.nu           # Display rendering
│   ├── project-dashboard.nu      # Project-specific dashboard
│   ├── simple-dashboard.nu       # Simplified dashboard
│   ├── size-dashboard.nu         # Size analysis dashboard
│   ├── status-dashboard.nu       # Status dashboard
│   ├── quality/                  # Code quality tools
│   └── benchmarks/               # Performance benchmarks
├── setup/            # System setup and installation
│   ├── simple-install.nu         # Basic installation
│   ├── simple-setup.nu           # Basic configuration setup
│   ├── unified-setup.nu          # All-in-one setup
│   ├── install.nu                # Installation tools
│   ├── setup-cachix.nu           # Cachix configuration
│   ├── setup-remote-builder.nu   # Remote builder setup
│   ├── setup-remote-builder.sh   # Shell version
│   ├── test-remote-builder.nu    # Remote builder testing
│   └── test-remote-builder.sh    # Shell version
├── testing/          # Testing and validation tools
│   ├── run-tests.nu              # Main test runner
│   ├── setup-coverage.nu         # Coverage setup
│   ├── generate-codecov.nu       # Codecov integration
│   ├── generate-lcov.nu          # LCOV coverage
│   ├── test-coverage-debug.nu    # Coverage debugging
│   ├── unit/                     # Unit tests
│   ├── integration/              # Integration tests
│   ├── performance/              # Performance tests (modular)
│   │   ├── performance-tests.nu # Main performance tests
│   │   └── modules/             # Performance test modules
│   │       ├── system.nu        # System performance
│   │       └── build.nu         # Build performance
│   ├── display/                  # Display tests (modular)
│   │   ├── display-tests.nu     # Main display tests
│   │   └── modules/             # Display test modules
│   │       ├── hardware.nu      # Hardware detection
│   │       ├── config.nu        # Configuration analysis
│   │       └── safety.nu        # Safety procedures
│   ├── storage/                  # Storage tests
│   ├── linux/                    # Linux-specific tests
│   ├── macos/                    # macOS-specific tests
│   ├── windows/                  # Windows-specific tests
│   └── lib/                      # Test libraries
├── validation/       # System validation tools
│   ├── pre-rebuild-safety-check.nu    # Pre-rebuild validation
│   ├── safe-flake-test.nu             # Flake testing
│   ├── validate-display-config.nu     # Display validation
│   └── validate-gaming-config.nu      # Gaming validation
├── platforms/        # Platform-specific tools
│   ├── linux/                    # Linux-specific scripts
│   ├── macos/                    # macOS-specific scripts
│   └── windows/                  # Windows-specific scripts
├── lib/              # Shared libraries and utilities
├── common/           # Common utilities and helpers
└── handlers/         # Event handlers and automation
```

## Script Categories

### Unified Libraries (Core)
- **Purpose**: Common functions used across all scripts
- **Location**: `scripts/lib/`
- **Key Libraries**: 
  - `unified-checks.nu` - Validation and system checks
  - `unified-error-handling.nu` - Error handling and logging
- **Usage**: Imported by all other scripts

### Storage Safety (Critical)
- **Purpose**: Prevent boot failures due to storage configuration issues
- **Location**: `scripts/storage/`
- **Key Tools**: `storage-guard.nu`, `fix-storage-config.nu`
- **Usage**: Run before every reboot

### Maintenance
- **Purpose**: System health, cleanup, and safe operations
- **Location**: `scripts/maintenance/`
- **Key Tools**: `health-check.nu`, `cleanup.nu`, `safe-rebuild.nu`
- **Usage**: Regular maintenance and before system changes

### Analysis
- **Purpose**: Performance analysis, reporting, and optimization
- **Location**: `scripts/analysis/`
- **Key Tools**: `analyze-sizes.nu`, `dashboard.nu`, `generate-docs.nu`
- **Usage**: Performance monitoring and optimization

### Setup
- **Purpose**: System installation and configuration
- **Location**: `scripts/setup/`
- **Key Tools**: `unified-setup.nu`, `simple-install.nu`
- **Usage**: Initial setup and configuration

### Testing
- **Purpose**: Comprehensive testing and validation
- **Location**: `scripts/testing/`
- **Key Tools**: `run-tests.nu`, `setup-coverage.nu`
- **Usage**: Development and CI/CD

### Validation
- **Purpose**: System validation and safety checks
- **Location**: `scripts/validation/`
- **Key Tools**: `validate-config.nu`, `pre-rebuild-safety-check.nu`
- **Usage**: Before system changes and rebuilds

### Platforms
- **Purpose**: Platform-specific tools and configurations
- **Location**: `scripts/platforms/`
- **Key Tools**: Platform-specific installation and maintenance
- **Usage**: Platform-specific operations

## Usage Guidelines

### Script Template
All scripts follow a consistent template:

```nushell
#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-error-handling.nu

def main [] {
    # Script logic here
    log_info "Starting execution"
    
    # Use unified functions
    let platform = (check_platform)
    
    log_success "Completed successfully"
}

# Run the main function
main
```

### Error Handling
Use the enhanced error handling library for consistent error reporting:

```nushell
# Safe command execution
let result = (safe_exec "command" "context")
if not $result.success {
    log_error $"Command failed: ($result.error)" "context"
    exit 1
}

# Require dependencies
require_command "nix" "script-name"
require_file "config/nixos/configuration.nix" "script-name"
```

### Validation Functions
Use unified validation functions for common checks:

```nushell
# Check if command exists
if (check_command "nix") {
    log_success "Nix is available"
}

# Check file existence
if (check_file "flake.nix") {
    log_success "flake.nix found"
}

# Check system health
let health = (check_system_services)
if $health.healthy {
    log_success "System services healthy"
}
```

## Key Scripts

### Critical Scripts
- **Storage Guard**: `scripts/storage/storage-guard.nu` - Pre-reboot validation
- **Health Check**: `scripts/maintenance/health-check.nu` - System health
- **Safe Rebuild**: `scripts/maintenance/safe-rebuild.nu` - Safe system rebuild
- **Validate Config**: `scripts/validation/validate-config.nu` - Configuration validation

### Setup Scripts
- **Unified Setup**: `scripts/setup/unified-setup.nu` - Complete setup
- **Simple Install**: `scripts/setup/simple-install.nu` - Basic installation
- **Setup Cachix**: `scripts/setup/setup-cachix.nu` - Cachix configuration

### Analysis Scripts
- **Dashboard**: `scripts/analysis/dashboard.nu` - System dashboard
- **Analyze Sizes**: `scripts/analysis/analyze-sizes.nu` - Package analysis
- **Generate Docs**: `scripts/analysis/generate-docs.nu` - Documentation

### Testing Scripts
- **Run Tests**: `scripts/testing/run-tests.nu` - Test runner
- **Setup Coverage**: `scripts/testing/setup-coverage.nu` - Coverage setup
- **Unit Tests**: `scripts/testing/unit/` - Unit test suite

## Development

### Adding New Scripts
1. Follow the script template
2. Import unified libraries
3. Use consistent error handling
4. Add proper documentation
5. Test on multiple platforms

### Testing Scripts
```bash
# Run all tests
nu scripts/testing/run-tests.nu

# Run specific test categories
nu scripts/testing/unit/unit-tests.nu
nu scripts/testing/integration/integration-tests.nu

# Test individual scripts
nu -c "source scripts/your-script.nu"
```

### Debugging
Enable verbose logging for debugging:
```bash
# Most scripts support --verbose flag
nu scripts/maintenance/health-check.nu --verbose

# Check script syntax
nu -c "source scripts/your-script.nu"
```

## Best Practices

### Code Style
- Use unified libraries for consistency
- Follow the script template
- Include proper error handling
- Add documentation for complex functions

### Performance
- Use efficient validation functions
- Minimize external command calls
- Cache results when appropriate
- Use appropriate data structures

### Security
- Validate all inputs
- Use safe execution functions
- Handle sensitive data properly
- Follow principle of least privilege

### Maintainability
- Keep scripts focused and single-purpose
- Use descriptive variable names
- Add comments for complex logic
- Follow consistent naming conventions
