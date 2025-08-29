# Function Naming Convention Guide

## Overview

This guide establishes consistent function naming conventions across the nix-mox codebase to improve readability, maintainability, and developer experience.

## 🎯 Naming Convention: snake_case

All function names in nix-mox should use **snake_case** formatting.

### ✅ Preferred Examples:
```nu
def validate_disk_space [] { ... }
def check_system_health [] { ... }
def install_homebrew_packages [] { ... }
def generate_security_report [] { ... }
def backup_configuration_files [] { ... }
```

### ❌ Avoid These Patterns:
```nu
# kebab-case (being migrated away from)
def validate-disk-space [] { ... }
def check-system-health [] { ... }

# camelCase
def validateDiskSpace [] { ... }
def checkSystemHealth [] { ... }

# PascalCase
def ValidateDiskSpace [] { ... }
def CheckSystemHealth [] { ... }
```

## 📝 Guidelines

### 1. Use Descriptive Verbs
Start function names with clear action verbs:
- `validate_` for validation functions
- `check_` for status checking
- `install_` for installation functions
- `backup_` for backup operations
- `generate_` for creating content
- `parse_` for parsing operations

### 2. Be Specific and Clear
```nu
# ✅ Good - specific and descriptive
def validate_storage_configuration [] { ... }
def check_network_connectivity [] { ... }
def install_nix_packages [] { ... }

# ❌ Poor - too vague
def check_stuff [] { ... }
def do_thing [] { ... }
def handle_data [] { ... }
```

### 3. Single-Word Functions Are OK
For common, well-understood operations:
```nu
def validate [] { ... }
def install [] { ... }
def backup [] { ... }
def deploy [] { ... }
```

### 4. Avoid Abbreviations
Unless they're widely understood in the context:
```nu
# ✅ Good
def get_system_information [] { ... }
def check_configuration_syntax [] { ... }

# ❌ Unclear abbreviations
def get_sys_info [] { ... }  
def chk_cfg_syn [] { ... }
```

### 5. Boolean Functions
Use clear boolean prefixes:
```nu
def is_system_healthy [] { ... }
def has_valid_configuration [] { ... }
def can_connect_to_network [] { ... }
def should_run_backup [] { ... }
```

## 🔧 Migration Status

As of the latest standardization effort:

- ✅ **Core validation scripts** - Updated to snake_case
- ✅ **Dashboard and monitoring** - Updated to snake_case  
- ✅ **Storage validator** - Updated to snake_case
- ✅ **Analysis scripts** - Updated to snake_case
- ✅ **Platform scripts** - Partially updated
- ⚠️ **Test scripts** - Some kebab-case functions remain
- ⚠️ **Gaming scripts** - Some kebab-case functions remain

### Remaining Kebab-Case Functions to Update:

#### Test Scripts:
- `scripts/testing/windows/windows-tests.nu`
  - `test-windows-commands` → `test_windows_commands`
  - `test-nushell` → `test_nushell` 
  - `test-nix` → `test_nix`

#### Gaming Scripts:
- `scripts/gaming/setup-proton-ge.nu`
  - `check-mount-exec` → `check_mount_exec`
  - `list-proton` → `list_proton`

#### Platform Scripts:
- `scripts/platforms/macos/*.nu` - Several kebab-case functions
- `scripts/platforms/linux/*.nu` - Several kebab-case functions

## 🛠️ Tools

### Automated Detection
```bash
# Scan for naming patterns
nu scripts/lib/function-naming-fixer.nu scan

# List all kebab-case functions
nu scripts/lib/function-naming-fixer.nu list

# Show best practices guide
nu scripts/lib/function-naming-fixer.nu guide
```

### Manual Standardization
```bash
# Semi-automated standardization (experimental)
nu scripts/lib/function-naming-fixer.nu standardize
```

## 📊 Current Statistics

After recent standardization efforts:
- **~150+ functions** follow snake_case convention
- **~30 functions** still use kebab-case (being migrated)
- **0 functions** use camelCase or PascalCase ✅

## 🎯 Goal

Achieve 100% snake_case function naming throughout the codebase for:
- Consistent developer experience
- Improved code readability  
- Better tooling and IDE support
- Alignment with Nushell best practices

## 🤝 Contributing

When creating new functions:
1. Always use snake_case naming
2. Start with a descriptive verb
3. Be specific about the function's purpose
4. Avoid unnecessary abbreviations
5. Use boolean prefixes for boolean functions

When updating existing functions:
1. Update the function definition
2. Update all function calls in the same file
3. Search for calls in other files if it's an exported function
4. Update related documentation/comments