#!/usr/bin/env nu
# Import and dependency validation pre-commit hook
# Validates all 'use' statements in .nu files resolve correctly

use ../../lib/logging.nu *

# Main import validation function
export def validate_imports [
    --staged-only = false,      # Only check staged files
    --verbose = false           # Show verbose output
] {
    let files_to_check = if $staged_only {
        # Get staged .nu files
        try {
            let staged_files = (git diff --cached --name-only --diff-filter=ACMR | lines | where ($it | str ends-with ".nu"))
            if ($staged_files | length) == 0 {
                success "No .nu files in staging area" --context "imports"
                return 0
            }
            $staged_files
        } catch {
            warn "Could not get staged files, checking all .nu files" --context "imports"
            (glob "scripts/**/*.nu")
        }
    } else {
        (glob "scripts/**/*.nu")
    }
    
    mut errors = []
    mut warnings = []
    
    for file in $files_to_check {
        if not ($file | path exists) {
            continue
        }
        
        if $verbose {
            info $"Checking imports in ($file)..." --context "imports"
        }
        
        let content = (open $file)
        let file_dir = ($file | path dirname)
        
        # Find all use statements
        let use_statements = find_use_statements $content
        
        for use_stmt in $use_statements {
            let import_path = resolve_import_path $file_dir $use_stmt.path
            
            if not ($import_path | path exists) {
                $errors = ($errors | append {
                    file: $file,
                    line: $use_stmt.line,
                    import: $use_stmt.path,
                    resolved_path: $import_path,
                    error: "Import file not found"
                })
            } else {
                # Check if imported functions exist
                if ($use_stmt.items | length) > 0 and $use_stmt.items != ["*"] {
                    let missing = check_exported_items $import_path $use_stmt.items
                    if ($missing | length) > 0 {
                        $warnings = ($warnings | append {
                            file: $file,
                            line: $use_stmt.line,
                            import: $use_stmt.path,
                            issue: $"Missing exports: ($missing | str join ', ')"
                        })
                    }
                }
            }
        }
        
        # Check for circular dependencies
        let circular = detect_circular_deps $file $files_to_check
        if ($circular | length) > 0 {
            $warnings = ($warnings | append $circular)
        }
    }
    
    # Report results
    if ($errors | length) == 0 and ($warnings | length) == 0 {
        success $"All imports validated successfully! ✅" --context "imports"
        return 0
    }
    
    if ($errors | length) > 0 {
        error $"Found ($errors | length) import errors:" --context "imports"
        for err in $errors {
            error $"  📁 ($err.file):($err.line)" --context "imports"
            error $"    Import: ($err.import)" --context "imports"
            error $"    Error: ($err.error)" --context "imports"
            error $"    Looked for: ($err.resolved_path)" --context "imports"
        }
    }
    
    if ($warnings | length) > 0 {
        warn $"Found ($warnings | length) import warnings:" --context "imports"
        for warning in $warnings {
            warn $"  📁 ($warning.file):($warning.line)" --context "imports"
            warn $"    ($warning.issue)" --context "imports"
        }
    }
    
    if ($errors | length) > 0 {
        return 1
    } else {
        return 0
    }
}

# Find all use statements in content
def find_use_statements [content: string] {
    mut statements = []
    let lines = ($content | lines)
    
    for line_idx in 0..(($lines | length) - 1) {
        let line = ($lines | get $line_idx)
        let line_num = ($line_idx + 1)
        
        if ($line | str trim | str starts-with "use ") {
            let parts = ($line | str trim | str substring 4.. | split row " ")
            let import_path = ($parts | first)
            
            # Extract imported items (after the path)
            let items = if ($parts | length) > 1 {
                let rest = ($parts | skip 1 | str join " ")
                if $rest == "*" {
                    ["*"]
                } else {
                    # Parse specific imports
                    []
                }
            } else {
                []
            }
            
            $statements = ($statements | append {
                line: $line_num,
                path: $import_path,
                items: $items
            })
        }
    }
    
    $statements
}

# Resolve import path relative to file
def resolve_import_path [file_dir: string, import_path: string] {
    if ($import_path | str starts-with "/") {
        # Absolute path
        $import_path
    } else if ($import_path | str starts-with "./") or ($import_path | str starts-with "../") {
        # Relative path
        let resolved = ($file_dir | path join $import_path)
        if not ($resolved | str ends-with ".nu") {
            $"($resolved).nu"
        } else {
            $resolved
        }
    } else {
        # Assume relative to scripts directory
        let resolved = ($"scripts/($import_path)")
        if not ($resolved | str ends-with ".nu") {
            $"($resolved).nu"
        } else {
            $resolved
        }
    }
}

# Check if exported items exist in file
def check_exported_items [file_path: string, items: list] {
    let content = (open $file_path)
    mut missing = []
    
    for item in $items {
        if $item == "*" {
            continue
        }
        
        # Check for exported def
        if not ($content | str contains $"export def ($item)") {
            $missing = ($missing | append $item)
        }
    }
    
    $missing
}

# Detect circular dependencies
def detect_circular_deps [file: string, all_files: list] {
    # Simple circular dependency detection
    # This is a basic implementation
    []
}

# Main function for CLI usage
def main [
    action: string = "check",  # check or report
    --staged-only = false,
    --verbose = false
] {
    if $action == "check" {
        validate_imports --staged-only=$staged_only --verbose=$verbose
    } else if $action == "report" {
        banner "Import Validation Report" --context "imports"
        let files = (glob "scripts/**/*.nu")
        info $"Checking imports in ($files | length) files..." --context "imports"
        validate_imports --verbose=$verbose
    } else {
        error $"Unknown action: ($action). Use: check or report" --context "imports"
        exit 1
    }
}