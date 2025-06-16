# Contributing to nix-mox

## Development Setup

1. Install Nix:

   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Enter development environment:

   ```bash
   nix develop
   ```

## Guidelines

- Use `nixpkgs-fmt` for Nix files
- Follow existing code style
- Add comments for complex logic
- Keep functions focused

## Testing

```bash
nu scripts/core/run-tests.nu
```

## Pull Request Process

1. Fork and create feature branch
2. Make changes
3. Run tests
4. Submit PR

## Commit Messages

Use conventional commits:

- feat: new feature
- fix: bug fix
- docs: documentation
- style: formatting
- refactor: code changes
- test: tests
- chore: maintenance

## Questions?

Open an issue for any questions.
