# Development Workflow Guide

> Best practices for developing with nix-mox.

## Quick Development Commands

```bash
# Start development
make dev

# Run tests
make test

# Check code quality
make code-quality

# Format code
make format

# Build packages
make build-all
```

## Development Workflow

### 1. **Setup Development Environment**

```bash
# Enter development shell
make dev

# Or use specific shells
nix develop .#development
nix develop .#testing
nix develop .#gaming
```

### 2. **Before Making Changes**

```bash
# Update dependencies
make update

# Run existing tests
make test

# Check code quality
make code-quality
```

### 3. **During Development**

```bash
# Run tests frequently
make test

# Check syntax
make code-syntax

# Check security
make code-security

# Format code
make format
```

### 4. **Before Committing**

```bash
# Run pre-commit checks
nu scripts/pre-commit.nu

# Or run individual checks
make code-quality
make format
make test
```

### 5. **Before Pushing**

```bash
# Run comprehensive tests
make ci-local

# Generate documentation
make docs

# Check for TODOs/FIXMEs
make code-quality
```

## Code Quality Standards

### Code Style

- **Nix files**: Use `nixpkgs-fmt` for formatting
- **Nushell scripts**: Follow consistent indentation and naming
- **Documentation**: Use clear, concise language

### Quality Checks

```bash
# Comprehensive quality analysis
make code-quality

# Quick quality check
make quality

# Individual checks
make code-syntax
make code-security
```

### Pre-commit Hook

Install the pre-commit hook for automatic quality checks:

```bash
# Copy pre-commit hook
cp scripts/pre-commit.nu .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Or run manually:

```bash
nu scripts/pre-commit.nu
```

## Testing Strategy

### Test Types

1. **Unit Tests** - Test individual functions and modules
2. **Integration Tests** - Test system interactions
3. **Performance Tests** - Test system performance
4. **Display Tests** - Test display configuration safety

### Running Tests

```bash
# All tests
make test

# Unit tests only
make unit

# Integration tests only
make integration

# Specific test categories
make gaming-test
make display-test
make security-check
```

### Test Coverage

```bash
# Generate coverage report
make coverage

# View coverage dashboard
make coverage-local
```

## Documentation

### Writing Documentation

- Keep documentation up to date with code changes
- Use clear, concise language
- Include examples where helpful
- Update README files when adding new features

### Documentation Structure

```
docs/
├── USAGE.md              # Main usage guide
├── guides/               # Detailed guides
├── examples/             # Code examples
└── architecture/         # System architecture
```

## Security Practices

### Code Security

- Never commit secrets or passwords
- Use environment variables for sensitive data
- Run security checks before committing
- Review security findings from `make code-security`

### Security Checks

```bash
# Check for security issues
make code-security

# Validate security configuration
make security-check
```

## Performance Considerations

### Build Performance

- Use Cachix for build caching
- Optimize package dependencies
- Use parallel builds where possible
- Monitor build times with `make analyze-sizes`

### Runtime Performance

- Profile performance-critical code
- Use `make performance-analyze` for system analysis
- Optimize based on performance reports

## Troubleshooting

### Common Issues

1. **Build Failures**
   ```bash
   make clean-all
   make build-all
   ```

2. **Test Failures**
   ```bash
   make clean
   make test
   ```

3. **Quality Check Failures**
   ```bash
   make format
   make code-quality
   ```

### Getting Help

- Check existing issues on GitHub
- Review documentation in `docs/`
- Run `make help` for available commands
- Use `make health-check` for system validation

## Best Practices

### General

- Write tests for new features
- Update documentation with changes
- Use meaningful commit messages
- Review code before merging

### Code Quality

- Run quality checks frequently
- Address TODOs and FIXMEs promptly
- Follow established patterns
- Use consistent naming conventions

### Testing

- Test locally before pushing
- Use CI/CD for automated testing
- Maintain good test coverage
- Test edge cases and error conditions

### Documentation

- Keep documentation current
- Use clear examples
- Document breaking changes
- Update quick start guides

## CI/CD Integration

### GitHub Actions

The repository includes GitHub Actions workflows for:

- Automated testing
- Code quality checks
- Security scanning
- Documentation generation
- Release management

### Local CI Testing

```bash
# Quick CI test
make ci-test

# Comprehensive CI test
make ci-local
```

## Release Process

### Before Release

1. Run comprehensive tests
2. Update documentation
3. Check for TODOs/FIXMEs
4. Generate SBOM
5. Update version numbers

### Release Commands

```bash
# Generate release artifacts
make sbom
make docs

# Run release tests
make ci-local
make code-quality
```

## Contributing

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make changes following this workflow
4. Run all quality checks
5. Submit pull request

### Code Review

- Review for code quality
- Check test coverage
- Verify documentation updates
- Ensure security compliance

---

**Remember**: Quality is everyone's responsibility. Run quality checks frequently and address issues promptly.
