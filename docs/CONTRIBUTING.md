# Contributing to nix-mox

Thank you for your interest in contributing to nix-mox! This document provides guidelines and instructions for contributing.

## Development Setup

1. **Fork and Clone**

   ```bash
   git clone https://github.com/your-username/nix-mox.git
   cd nix-mox
   ```

2. **Development Environment**

   ```bash
   # Enter the development shell
   nix develop
   ```

## Code Style

### Nix Code

- Use `nix fmt` to format Nix files
- Follow the [Nixpkgs Style Guide](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md#code-style)
- Use meaningful variable names
- Add comments for complex logic

### Shell Scripts

- Follow [ShellCheck](https://github.com/koalaman/shellcheck) guidelines
- Use the `_common.sh` functions for logging and error handling
- Add proper error handling and cleanup
- Include usage documentation in script headers

## Testing

### Running Tests

```bash
# Run all tests
./tests/test-common.sh
./tests/test-zfs-snapshot.sh

# Test NixOS module
nix build .#nixosConfigurations.test-vm.config.system.build.toplevel

# Test all packages
nix build .#all
```

### Adding Tests

1. Create test files in `tests/` directory
2. Use mock commands for system interactions
3. Test both success and failure cases
4. Include cleanup in tests

## Documentation

### Updating Documentation

1. Update `ARCHITECTURE.md` for architectural changes
2. Update `USAGE.md` for usage changes
3. Add comments to code for complex logic
4. Update README.md for major changes

### Documentation Style

- Use Markdown for all documentation
- Include code examples where helpful
- Keep diagrams up to date
- Document all configuration options

## Pull Request Process

1. **Create a Branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Make your changes
   - Add tests
   - Update documentation
   - Run tests locally

3. **Commit Changes**

   ```bash
   git commit -m "feat: add your feature"
   ```

   Use conventional commit messages:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `test:` for tests
   - `chore:` for maintenance

4. **Push Changes**

   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**
   - Fill out the PR template
   - Link related issues
   - Ensure CI passes
   - Request review

## CI/CD

The project uses GitHub Actions for CI/CD. The pipeline:

- Runs on every push and PR
- Tests all components
- Builds packages
- Checks formatting
- Validates documentation

## Versioning

We follow [Semantic Versioning](https://semver.org/):

- MAJOR: Breaking changes
- MINOR: New features, backwards compatible
- PATCH: Bug fixes, backwards compatible

## Questions?

Feel free to:

- Open an issue for questions
- Join our discussions
- Contact maintainers

Thank you for contributing! 🎉
