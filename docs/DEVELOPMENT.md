# Development Guide

> Comprehensive guide for developing with nix-mox, including tools, workflows, and best practices.

## Quick Development Commands

```bash
# Format all code
nix run .#fmt

# Run tests
nix run .#test

# Update flake inputs
nix run .#update

# Enter development shell
nix develop
```

## Code Formatting

The project uses `treefmt` for consistent formatting across all file types:

```bash
# Format all files
nix run .#fmt

# Check formatting without changes
nix run .#formatter -- --check

# Format specific files
nix run .#formatter -- path/to/file.nix
```

### Supported File Types
- **Nix** (`.nix`) - `nixpkgs-fmt`
- **Shell scripts** (`.sh`, `.bash`, `.zsh`) - `shfmt` + `shellcheck`
- **Markdown** (`.md`, `.mdx`) - `prettier`
- **JSON/YAML** (`.json`, `.yml`, `.yaml`) - `prettier`
- **JavaScript/TypeScript** (`.js`, `.ts`, `.jsx`, `.tsx`) - `prettier`
- **CSS/SCSS** (`.css`, `.scss`, `.sass`) - `prettier`
- **HTML** (`.html`, `.htm`) - `prettier`
- **Python** (`.py`) - `black`
- **Rust** (`.rs`) - `rustfmt`
- **Go** (`.go`) - `gofmt`

## Development Shells

```bash
# Default development environment
nix develop

# Platform-specific shells
nix develop .#development      # General development
nix develop .#testing         # Testing tools
nix develop .#services        # Service tools (Linux)
nix develop .#monitoring      # Monitoring tools (Linux)
nix develop .#gaming          # Gaming tools (Linux)
nix develop .#macos           # macOS tools (macOS)
```

## Testing

```bash
# Run all tests
nix run .#test

# Run specific test suites
nix build .#checks.x86_64-linux.unit
nix build .#checks.x86_64-linux.integration
nix build .#checks.x86_64-linux.test-suite

# Platform-specific tests
nix build .#checks.x86_64-linux.linux-specific
nix build .#checks.x86_64-darwin.macos-specific

# Run tests with make (legacy)
make test
make unit
make integration
```

## Package Development

### Linux Packages
```bash
# Build specific packages
nix build .#proxmox-update
nix build .#vzdump-backup
nix build .#zfs-snapshot
nix build .#nixos-flake-update

# Run packages
nix run .#proxmox-update
nix run .#vzdump-backup
nix run .#zfs-snapshot
nix run .#nixos-flake-update
```

### macOS Packages
```bash
# Build specific packages
nix build .#homebrew-setup
nix build .#macos-maintenance
nix build .#xcode-setup
nix build .#security-audit

# Run packages
nix run .#homebrew-setup
nix run .#macos-maintenance
nix run .#xcode-setup
nix run .#security-audit
```

### Installation Packages
```bash
# Build installation packages
nix build .#install
nix build .#uninstall

# Run installation
nix run .#install
nix run .#uninstall
```

## Configuration Files

- **`flake.nix`** - Main flake configuration with apps, packages, and checks
- **`treefmt.nix`** - Nix-based formatting configuration
- **`.treefmt.toml`** - TOML-based formatting configuration (better IDE support)

## Development Workflow

### 1. Setup Development Environment
```bash
# Clone and enter project
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# Enter development shell
nix develop
```

### 2. Make Changes
```bash
# Edit files in your preferred editor
# The development shell includes common development tools
```

### 3. Format Code
```bash
# Format all files
nix run .#fmt

# Check formatting without changes
nix run .#formatter -- --check
```

### 4. Run Tests
```bash
# Run all tests
nix run .#test

# Run specific test suites
nix build .#checks.x86_64-linux.unit
```

### 5. Build Packages
```bash
# Build all packages for your system
nix build

# Build specific packages
nix build .#proxmox-update
```

### 6. Update Dependencies
```bash
# Update flake inputs
nix run .#update

# Or manually
nix flake update
```

## IDE Integration

### VS Code/Cursor
The development shell includes:
- **Cursor IDE** - Modern code editor
- **Kitty terminal** - Fast terminal emulator
- **Development tools** - Git, debugging tools, etc.

### Formatting Integration
Install the `treefmt` extension and configure it to use the project's configuration:

```json
{
  "treefmt.config": "./.treefmt.toml"
}
```

### Pre-commit Hooks
Consider setting up pre-commit hooks for automatic formatting:

```bash
# Install pre-commit
pip install pre-commit

# Create .pre-commit-config.yaml
repos:
  - repo: https://github.com/numtide/treefmt
    rev: v0.5.2
    hooks:
      - id: treefmt
        args: [--fail-on-change]
```

## Troubleshooting

### Formatting Issues
```bash
# Check what would be formatted
nix run .#formatter -- --check

# Show formatting differences
nix run .#formatter -- --diff

# Validate configuration
nix run .#formatter -- --config-help
```

### Build Issues
```bash
# Check flake configuration
nix flake check

# Build with verbose output
nix build --verbose

# Check specific package
nix build .#package-name --verbose
```

### Test Issues
```bash
# Run tests with verbose output
nix build .#checks.x86_64-linux.test-suite --verbose

# Check test configuration
nix eval .#checks.x86_64-linux.test-suite
```

## Best Practices

### Code Style
- Use `nix run .#fmt` before committing
- Follow existing code patterns
- Add comments for complex logic
- Keep functions focused and small

### Testing
- Write tests for new features
- Ensure all tests pass before submitting PRs
- Use appropriate test suites (unit, integration, platform-specific)

### Package Development
- Test packages on target platforms
- Include proper error handling
- Add documentation for package usage
- Follow naming conventions

### Git Workflow
- Use conventional commit messages
- Create feature branches for changes
- Test changes locally before pushing
- Update documentation when adding features

## Continuous Integration

The project uses GitHub Actions for CI/CD with:
- **Multi-platform testing** (Linux, macOS)
- **Package building** and validation
- **Code formatting** checks
- **Test execution** with coverage reporting

All changes must pass CI before merging.

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/Hydepwns/nix-mox/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Hydepwns/nix-mox/discussions)
- **Documentation**: Check other guides in `docs/`
- **Examples**: See `docs/examples/` for usage examples 