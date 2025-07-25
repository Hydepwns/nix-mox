# nix-mox Scripts Documentation

This directory contains automatically generated documentation for all nix-mox scripts.

## Files

- `README.md` - This file
- `scripts-reference.md` - Complete script reference
- `scripts-index.json` - JSON index of all scripts

- `core-scripts.md` - $category scripts 13
- `tools-scripts.md` - $category scripts 9
- `general-scripts.md` - $category scripts 17

## Statistics

- Total scripts: ($scripts | length)
- Categories: ($categories | length)
- Platforms supported: ($scripts | get platform | uniq | length)

## Regeneration

To regenerate this documentation:

```bash
./scripts/tools/generate-docs.nu
```

For more options:

```bash
./scripts/tools/generate-docs.nu --help
```