# Contributing to nix-mox

Thank you for your interest in contributing to nix-mox! This document provides guidelines and instructions for contributing.

## Development Setup

1. Install Nix:

   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Enter the development shell:

   ```bash
   nix develop
   ```

## Code Style

- Use `nixpkgs-fmt` for formatting Nix files
- Follow the existing code style in each file
- Add comments for complex logic
- Keep functions small and focused

## Testing

Run the test suite:

```bash
nu scripts/core/run-tests.nu
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Commit Messages

Follow conventional commits format:

- feat: new feature
- fix: bug fix
- docs: documentation changes
- style: formatting changes
- refactor: code refactoring
- test: adding tests
- chore: maintenance tasks

## Questions?

Feel free to open an issue for any questions or concerns.
