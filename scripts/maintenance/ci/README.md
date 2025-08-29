# CI/CD Scripts and Pre-commit Hooks

This directory contains comprehensive validation scripts and pre-commit hooks for maintaining code quality.

## Pre-commit Hooks

### Setup
```bash
# Git is already configured to use .githooks directory
# Hooks are automatically active after cloning the repository
git config core.hooksPath .githooks
```

### Available Hooks

#### 1. **Function Naming Check** (`function-naming-check.nu`)
- Enforces snake_case naming convention for all functions
- Auto-fix capability with `--fix` flag
- Currently at 100% compliance (693 functions)

```bash
nu scripts/maintenance/ci/function-naming-check.nu check
nu scripts/maintenance/ci/function-naming-check.nu fix
nu scripts/maintenance/ci/function-naming-check.nu report
```

#### 2. **Nushell Syntax Validation** (`nushell-syntax-check.nu`)
- Validates all `.nu` files for syntax errors
- Checks for deprecated patterns and style issues
- Provides warnings for improvements

```bash
nu scripts/maintenance/ci/nushell-syntax-check.nu check
nu scripts/maintenance/ci/nushell-syntax-check.nu report
```

#### 3. **Secret Detection** (`secret-detection.nu`)
- Scans for API keys, passwords, tokens, and credentials
- Detects patterns for AWS, GitHub, database URLs, SSH keys
- Skips binary files and CI directories

```bash
nu scripts/maintenance/ci/secret-detection.nu scan
nu scripts/maintenance/ci/secret-detection.nu report
```

#### 4. **Nix Syntax Validation** (`nix-syntax-check.nu`)
- Validates `.nix` files using `nix-instantiate`
- Checks for hardcoded paths and insecure patterns
- Suggests best practices

```bash
nu scripts/maintenance/ci/nix-syntax-check.nu check
nu scripts/maintenance/ci/nix-syntax-check.nu report
```

#### 5. **Import Validation** (`import-validation.nu`)
- Validates all `use` statements resolve correctly
- Checks that exported functions exist
- Detects missing dependencies

```bash
nu scripts/maintenance/ci/import-validation.nu check
nu scripts/maintenance/ci/import-validation.nu report
```

#### 6. **Large File Detection** (`large-file-check.nu`)
- Prevents commits of files over 10MB
- Warns for files over 1MB
- Provides repository size analysis

```bash
nu scripts/maintenance/ci/large-file-check.nu check
nu scripts/maintenance/ci/large-file-check.nu size-report
```

#### 7. **Commit Message Validation** (`commit-msg-check.nu`)
- Enforces conventional commit format
- Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert, wip
- Format: `<type>(<scope>): <subject>`

```bash
nu scripts/maintenance/ci/commit-msg-check.nu validate "feat: add new feature"
nu scripts/maintenance/ci/commit-msg-check.nu examples
```

## Pre-commit Workflow

The pre-commit hook runs all checks automatically:

1. Function naming consistency
2. Nushell syntax validation
3. Secret detection
4. Nix syntax validation
5. Import validation
6. Large file detection

The commit-msg hook validates commit message format.

## Manual Checks

Run all checks manually:
```bash
# Check staged files only
nu scripts/maintenance/ci/function-naming-check.nu check --staged-only=true
nu scripts/maintenance/ci/nushell-syntax-check.nu check --staged-only=true
nu scripts/maintenance/ci/secret-detection.nu scan --staged-only=true
nu scripts/maintenance/ci/nix-syntax-check.nu check --staged-only=true
nu scripts/maintenance/ci/import-validation.nu check --staged-only=true
nu scripts/maintenance/ci/large-file-check.nu check --staged-only=true

# Or run the pre-commit hook directly
.githooks/pre-commit
```

## Configuration

- **Max file size**: 10MB (configurable in `large-file-check.nu`)
- **Warning file size**: 1MB
- **Commit message max line length**: 72 characters
- **Function naming**: snake_case only

## Troubleshooting

If hooks are not running:
```bash
# Verify hooks path
git config core.hooksPath

# Set hooks path if needed
git config core.hooksPath .githooks

# Make hooks executable
chmod +x .githooks/*
```

## Development

To bypass hooks temporarily (not recommended):
```bash
git commit --no-verify -m "message"
```

To test hooks without committing:
```bash
# Test pre-commit
.githooks/pre-commit

# Test commit message
echo "feat: test message" | nu scripts/maintenance/ci/commit-msg-check.nu validate
```