# macOS Shell Guide

This guide covers the optimized macOS development environment for nix-mox, including fast Nushell setup and CI improvements.

## Quick Start

### Using the Optimized Setup

The nix-mox project now uses the [setup-nu GitHub Action](https://github.com/marketplace/actions/setup-nu) for fast Nushell installation on macOS, avoiding the slow build-from-source process. The project uses Nushell version 0.104 for stability and compatibility.

```bash
# Enter the default development shell
nix develop

# Or enter the macOS-specific shell
nix develop .#macos
```

### Manual Nushell Installation (Alternative)

If you prefer to install Nushell manually:

```bash
# Using Homebrew (recommended for macOS)
brew install nushell

# Or using the official installer
curl -sSf https://get.nushell.sh | sh
```

## CI/CD Optimizations

### Fast macOS Workflows

The project includes optimized CI workflows for macOS:

1. **macos-optimized.yml**: Fast evaluation and essential package builds
2. **tests.yml**: Updated to use setup-nu action
3. **ci.yml**: Optimized with reduced timeouts

### Performance Improvements

- **Before**: 60+ minutes for macOS builds (building Nushell from source)
- **After**: 15-30 minutes for macOS builds (using pre-built Nushell)

### Key Changes

1. **setup-nu Action**: Uses pre-built Nushell binaries
2. **Reduced Timeouts**: macOS builds now timeout at 15-30 minutes instead of 60+
3. **Smart Dependencies**: Uses system Nushell when available
4. **Fast Evaluation**: Quick flake evaluation without building packages

## Development Workflow

### Local Development

```bash
# Enter development shell with all tools
nix develop .#development

# Run tests
nix flake check

# Build packages
nix build .#install .#uninstall
```

### Testing

```bash
# Run unit tests
nix flake check .#checks.unit

# Run integration tests
nix flake check .#checks.integration

# Run full test suite
nix flake check .#checks.test-suite
```

## Platform-Specific Features

### macOS-Specific Tools

- **homebrew-setup**: Automated Homebrew installation and configuration
- **macos-maintenance**: System maintenance scripts
- **xcode-setup**: Xcode command line tools setup
- **security-audit**: Security auditing tools

### Environment Variables

The shell automatically sets these environment variables:

```bash
NIX_MOX_PLATFORM=x86_64-darwin  # or aarch64-darwin
NIX_MOX_IS_DARWIN=true
NIX_MOX_ARCH=x86_64  # or aarch64
```

## Troubleshooting

### Common Issues

1. **Slow CI Builds**: Ensure you're using the optimized workflows
2. **Nushell Not Found**: The shell will automatically use system Nushell if available
3. **Architecture Mismatches**: The optimized workflows handle cross-architecture builds

### Performance Tips

1. **Use setup-nu Action**: Always use the setup-nu action in CI workflows
2. **Limit Package Builds**: Only build essential packages on macOS
3. **Fast Evaluation**: Use `nix flake show` and `nix flake metadata` for quick checks

## Migration from Old Setup

If you were using the old setup that built Nushell from source:

1. **Update Workflows**: Use the new optimized workflows
2. **Remove Manual Builds**: No need to manually build Nushell
3. **Update Dependencies**: The flake now uses system Nushell when available

## Contributing

When contributing to the macOS support:

1. **Test with setup-nu**: Always test with the setup-nu action
2. **Keep Builds Fast**: Avoid adding heavy dependencies to macOS builds
3. **Use Pre-built Binaries**: Prefer pre-built binaries over source builds
4. **Document Changes**: Update this guide when making changes

## References

- [setup-nu GitHub Action](https://github.com/marketplace/actions/setup-nu)
- [Nushell Installation Guide](https://www.nushell.sh/book/installation.html)
- [GitHub Actions macOS Runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-software)
