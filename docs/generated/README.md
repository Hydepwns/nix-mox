# nix-mox Scripts Documentation

This directory contains automatically generated documentation for all nix-mox scripts.

## Files

- `README.md` - This file
- `scripts-reference.md` - Complete script reference
- `scripts-index.json` - JSON index of all scripts

- `general-scripts.md` - $category scripts 61
- `maintenance-scripts.md` - $category scripts 3
- `testing-scripts.md` - $category scripts 6
- `platform-scripts.md` - $category scripts 2

## Statistics

- Total scripts: ($scripts | length)
- Categories: ($categories | length)
- Platforms supported: ($scripts | get platform | uniq | length)

## Regeneration

To regenerate this documentation:

```bash
./scripts/analysis/generate-docs.nu
```

For more options:

```bash
./scripts/analysis/generate-docs.nu --help
```