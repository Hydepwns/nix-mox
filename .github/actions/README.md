# Custom GitHub Actions for nix-mox

This directory contains custom GitHub Actions that can be used in nix-mox workflows.

## Available Actions

### `setup-nix`

Sets up Nix with custom configuration for nix-mox projects.

**Inputs:**

- `nix-version` (optional): Nix version to install (default: `2.19.2`)
- `extra-trusted-public-keys` (optional): Additional trusted public keys

**Usage:**

```yaml
- name: Setup Nix
  uses: ./.github/actions/setup-nix
  with:
    nix-version: '2.20.1'
    extra-trusted-public-keys: 'cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY='
```

### `run-tests`

Runs comprehensive tests for nix-mox with coverage reporting.

**Inputs:**

- `test-suites` (optional): Test suites to run (default: `unit,integration`)
- `verbose` (optional): Enable verbose output (default: `false`)
- `generate-coverage` (optional): Generate coverage report (default: `true`)

**Usage:**

```yaml
- name: Run Tests
  uses: ./.github/actions/run-tests
  with:
    test-suites: 'unit,integration,storage'
    verbose: 'true'
    generate-coverage: 'true'
```

## Benefits of Custom Actions

1. **Reusability**: Actions can be used across multiple workflows
2. **Consistency**: Ensures consistent setup and execution across workflows
3. **Maintainability**: Centralized logic for common tasks
4. **Versioning**: Actions can be versioned and updated independently

## Development

To add new actions:

1. Create a new directory under `.github/actions/`
2. Add an `action.yml` file with the action definition
3. Use composite actions for multi-step operations
4. Document the action in this README

## Example Workflow Usage

```yaml
name: Test with Custom Actions

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Nix
        uses: ./.github/actions/setup-nix
        
      - name: Setup Nushell
        uses: hustcer/setup-nu@v3
        with:
          version: "0.104"
          
      - name: Run Tests
        uses: ./.github/actions/run-tests
        with:
          test-suites: 'unit,integration'
          verbose: 'true'
```
