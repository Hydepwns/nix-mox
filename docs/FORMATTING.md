# Code Formatting Guide

> Comprehensive guide for code formatting in nix-mox using treefmt for consistent style across all file types.

## Overview

nix-mox uses `treefmt` for consistent code formatting across all supported file types. This ensures uniform code style and improves readability across the entire project.

## Quick Format

```bash
# Format all files
nix run .#fmt

# Check formatting without changes
nix run .#formatter -- --check

# Format specific files
nix run .#formatter -- path/to/file.nix

# Show formatting differences
nix run .#formatter -- --diff
```

## Configuration

The project includes two formatting configuration files:

- **`treefmt.nix`** - Nix-based configuration (used by the flake)
- **`.treefmt.toml`** - TOML-based configuration (better IDE support)

Both files define the same formatting rules for consistency.

## Supported Languages

### Nix
- **Tool**: `nixpkgs-fmt`
- **Files**: `*.nix`
- **Configuration**: Automatic
- **Features**: 
  - Consistent indentation
  - Proper spacing around operators
  - Function argument alignment
  - List and attribute set formatting

### Shell Scripts
- **Tool**: `shfmt` + `shellcheck`
- **Files**: `*.sh`, `*.bash`, `*.zsh`
- **Configuration**: 
  - 2-space indentation
  - Consistent quoting
  - Proper line breaks
  - Shell script linting
- **Features**:
  - Automatic quote normalization
  - Proper spacing around operators
  - Consistent function declarations

### Markdown
- **Tool**: `prettier`
- **Files**: `*.md`, `*.mdx`
- **Configuration**: 
  - 80-character line width
  - Prose wrapping enabled
  - Consistent list formatting
- **Features**:
  - Automatic link formatting
  - Consistent heading styles
  - Proper table formatting
  - Code block indentation

### JSON/YAML
- **Tool**: `prettier`
- **Files**: `*.json`, `*.yml`, `*.yaml`
- **Configuration**: 
  - 80-character line width
  - Consistent indentation
- **Features**:
  - Proper key ordering
  - Consistent quote usage
  - Array and object formatting

### JavaScript/TypeScript
- **Tool**: `prettier`
- **Files**: `*.js`, `*.ts`, `*.jsx`, `*.tsx`
- **Configuration**: 
  - 80-character line width
  - Semicolons enabled
  - Single quotes preferred
  - Trailing commas in objects/arrays
- **Features**:
  - Automatic import sorting
  - Consistent function declarations
  - Proper JSX formatting

### CSS/SCSS
- **Tool**: `prettier`
- **Files**: `*.css`, `*.scss`, `*.sass`
- **Configuration**: 
  - 80-character line width
  - Consistent property ordering
- **Features**:
  - Automatic vendor prefix handling
  - Consistent color formatting
  - Proper selector formatting

### HTML
- **Tool**: `prettier`
- **Files**: `*.html`, `*.htm`
- **Configuration**: 
  - 80-character line width
  - Consistent attribute ordering
- **Features**:
  - Proper tag indentation
  - Attribute line breaking
  - Consistent quote usage

### Python
- **Tool**: `black`
- **Files**: `*.py`
- **Configuration**: 
  - 88-character line width
  - Python 3.9+ target
  - String quote normalization
- **Features**:
  - Automatic import sorting
  - Consistent function formatting
  - Proper class declarations

### Rust
- **Tool**: `rustfmt`
- **Files**: `*.rs`
- **Configuration**: 
  - Edition 2021
  - Standard Rust formatting
- **Features**:
  - Consistent function formatting
  - Proper struct/enum formatting
  - Import organization

### Go
- **Tool**: `gofmt`
- **Files**: `*.go`
- **Configuration**: 
  - Standard Go formatting
  - Automatic import organization
- **Features**:
  - Consistent function declarations
  - Proper struct formatting
  - Import path formatting

## IDE Integration

### VS Code/Cursor
Install the `treefmt` extension and configure it to use the project's configuration:

```json
{
  "treefmt.config": "./.treefmt.toml",
  "treefmt.enable": true,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "numtide.treefmt"
}
```

### Neovim
Use `null-ls` or `conform.nvim` with treefmt integration:

```lua
-- For null-ls
require("null-ls").setup({
  sources = {
    require("null-ls").builtins.formatting.treefmt,
  },
})

-- For conform.nvim
require("conform").setup({
  formatters_by_ft = {
    nix = { "treefmt" },
    sh = { "treefmt" },
    markdown = { "treefmt" },
    -- Add other file types as needed
  },
})
```

### Emacs
Use `format-all` with treefmt support:

```elisp
(require 'format-all)
(add-to-list 'format-all-formatters '(nix "treefmt"))
(add-to-list 'format-all-formatters '(sh "treefmt"))
```

## Pre-commit Hooks

Set up pre-commit hooks for automatic formatting:

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
        types: [file]
        types_or: [nix, sh, markdown, json, yaml, javascript, typescript, css, html, python, rust, go]
```

## Git Hooks

Add formatting to your git workflow:

```bash
# Create .git/hooks/pre-commit
#!/bin/sh
nix run .#fmt
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Configuration Details

### Global Settings
The formatting configuration excludes certain directories and files:
- Build artifacts (`result`, `result-*`)
- Version control (`.git`, `.github`)
- Dependencies (`node_modules`)
- Lock files (`*.lock`, `flake.lock`)
- Temporary files (`tmp`, `tmp-*`)
- Generated files (`version`, `sbom`, `coverage-tmp`)

### Formatter-Specific Settings

#### Shell Scripts (shfmt)
```toml
[formatter.shell]
command = "shfmt"
options = ["-i", "2", "-ci", "-sr", "-w"]
```
- `-i 2`: 2-space indentation
- `-ci`: Case indentation for switch statements
- `-sr`: Space after redirect operators
- `-w`: Write changes to files

#### Shell Scripts (shellcheck)
```toml
[formatter.shellcheck]
command = "shellcheck"
options = ["--color=always", "--shell=bash"]
```
- `--color=always`: Always show colored output
- `--shell=bash`: Use bash as the target shell

#### Markdown (prettier)
```toml
[formatter.markdown]
command = "prettier"
options = ["--parser", "markdown", "--prose-wrap", "always", "--print-width", "80"]
```
- `--parser markdown`: Use markdown parser
- `--prose-wrap always`: Always wrap prose text
- `--print-width 80`: 80-character line width

## Troubleshooting

### Formatting Issues
```bash
# Check what would be formatted
nix run .#formatter -- --check

# Show formatting differences
nix run .#formatter -- --diff

# Validate configuration
nix run .#formatter -- --config-help

# Test configuration
nix run .#formatter -- --config .treefmt.toml --check
```

### Common Problems

#### Files Not Being Formatted
- Check if the file type is supported
- Verify the file is not in the exclude list
- Ensure the formatter is properly installed

#### Inconsistent Formatting
- Clear any existing formatting cache
- Ensure you're using the project's configuration
- Check for conflicting formatter configurations

#### Performance Issues
- Use `--check` mode for CI/CD
- Format only changed files when possible
- Consider using pre-commit hooks for selective formatting

### Debugging

#### Verbose Output
```bash
# Run with verbose output
nix run .#formatter -- --verbose

# Check formatter version
nix run .#formatter -- --version
```

#### Configuration Validation
```bash
# Validate TOML configuration
nix run .#formatter -- --config .treefmt.toml --check

# Validate Nix configuration
nix eval .#formatter
```

## Best Practices

### For Developers
1. **Format before committing** - Use `nix run .#fmt` before each commit
2. **Use IDE integration** - Configure your editor to format on save
3. **Check formatting in CI** - Ensure CI runs formatting checks
4. **Document custom rules** - Add comments for non-standard formatting

### For Maintainers
1. **Keep configurations simple** - Avoid overly complex formatting rules
2. **Test configurations** - Verify formatting works across all file types
3. **Update documentation** - Keep this guide current with configuration changes
4. **Monitor performance** - Ensure formatting doesn't slow down development

### For CI/CD
1. **Use check mode** - Run `--check` in CI to fail on formatting issues
2. **Cache formatters** - Cache formatter installations for faster builds
3. **Parallel execution** - Run formatting checks in parallel when possible
4. **Clear reporting** - Provide clear feedback on formatting failures

## Migration Guide

### From Manual Formatting
If you're migrating from manual formatting tools:

1. **Install treefmt** - Already included in the flake
2. **Configure your editor** - Set up IDE integration
3. **Update CI/CD** - Replace manual formatting commands with treefmt
4. **Test thoroughly** - Ensure all file types are properly formatted

### From Other Formatters
If you're migrating from other formatters:

1. **Compare configurations** - Ensure equivalent formatting rules
2. **Test with sample files** - Verify formatting matches expectations
3. **Update documentation** - Remove references to old formatters
4. **Train team** - Ensure everyone knows the new workflow

## Contributing

When contributing to the formatting configuration:

1. **Test changes** - Verify formatting works for all affected file types
2. **Update documentation** - Keep this guide current
3. **Consider impact** - Ensure changes don't break existing workflows
4. **Follow conventions** - Maintain consistency with existing configuration 