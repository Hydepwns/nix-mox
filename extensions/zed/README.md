# nix-mox Zed Extension

Enhanced Nushell development experience with nix-mox integration for Zed editor.

## Features

- **Nushell Language Support**: Full syntax highlighting and language server integration
- **nix-mox Commands**: Integrated commands for running scripts, testing, and validation
- **Code Snippets**: 10+ nix-mox specific snippets for rapid development
- **Custom Themes**: nix-mox Dark and Light themes optimized for Nushell development
- **Security Validation**: Built-in security scanning for Nushell scripts
- **Performance Metrics**: Real-time performance monitoring integration

## Installation

### From Source

```bash
# Navigate to the extension directory
cd extensions/zed

# Build the extension
cargo build --release

# Install in Zed
# Copy the built extension to Zed's extensions directory
```

### Development Installation

```bash
# Build for development
cargo build

# Run with Zed in development mode
```

## Commands

- `nix-mox:run-script` - Execute current Nushell script
- `nix-mox:test-script` - Run tests for current script
- `nix-mox:validate-security` - Security validation scan
- `nix-mox:show-metrics` - Display performance metrics
- `nix-mox:generate-docs` - Generate documentation
- `nix-mox:setup-wizard` - Launch setup wizard

## Snippets

- `nixmox-header` - Complete script template
- `nixmox-test` - Test function template
- `nixmox-error` - Error handling template
- `nixmox-platform` - Platform detection
- `nixmox-config` - Configuration access
- `nixmox-perf` - Performance monitoring
- `nixmox-log` - Logging function
- `nixmox-security` - Security validation
- `nixmox-metrics` - Metrics tracking
- `nixmox-imports` - Common imports

## Themes

- **nix-mox Dark**: Dark theme optimized for Nushell development
- **nix-mox Light**: Light theme with nix-mox branding

## Development

```bash
# Build extension
cargo build

# Run tests
cargo test

# Format code
cargo fmt

# Check linting
cargo clippy
```

## License

MIT License - see LICENSE file for details. 
