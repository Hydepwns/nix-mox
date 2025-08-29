#!/usr/bin/env nu
# Nix syntax validation pre-commit hook
# Validates all .nix files for correct syntax

use ../../lib/logging.nu *

# Main Nix syntax check function
export def check_nix_syntax [
    --staged-only = false,      # Only check staged files
    --verbose = false           # Show verbose output
] {
    let files_to_check = if $staged_only {
        # Get staged .nix files
        try {
            let staged_files = (git diff --cached --name-only --diff-filter=ACMR | lines | where ($it | str ends-with ".nix"))
            if ($staged_files | length) == 0 {
                success "No .nix files in staging area" --context "nix-syntax"
                return 0
            }
            $staged_files
        } catch {
            warn "Could not get staged files, checking all .nix files" --context "nix-syntax"
            (glob "**/*.nix")
        }
    } else {
        (glob "**/*.nix")
    }
    
    mut errors = []
    mut warnings = []
    
    for file in $files_to_check {
        if not ($file | path exists) {
            continue
        }
        
        if $verbose {
            info $"Checking ($file)..." --context "nix-syntax"
        }
        
        # Check syntax using nix-instantiate
        let result = (do { nix-instantiate --parse $file } | complete)
        
        if $result.exit_code != 0 {
            $errors = ($errors | append {
                file: $file,
                error: $result.stdout
            })
        } else {
            # Additional checks for common Nix issues
            let content = (open $file)
            let checks = check_nix_issues $file $content
            if ($checks | length) > 0 {
                $warnings = ($warnings | append $checks)
            }
        }
    }
    
    # Report results
    if ($errors | length) == 0 and ($warnings | length) == 0 {
        success $"All ($files_to_check | length) Nix files have valid syntax! ✅" --context "nix-syntax"
        return 0
    }
    
    if ($errors | length) > 0 {
        error $"Found ($errors | length) Nix syntax errors:" --context "nix-syntax"
        for err in $errors {
            error $"  📁 ($err.file):" --context "nix-syntax"
            error $"    ($err.error)" --context "nix-syntax"
        }
    }
    
    if ($warnings | length) > 0 {
        warn $"Found ($warnings | length) potential Nix issues:" --context "nix-syntax"
        for warning in $warnings {
            warn $"  📁 ($warning.file):($warning.line)" --context "nix-syntax"
            warn $"    ($warning.issue)" --context "nix-syntax"
        }
    }
    
    if ($errors | length) > 0 {
        return 1
    } else {
        return 0
    }
}

# Check for common Nix issues
def check_nix_issues [file: string, content: string] {
    mut issues = []
    let lines = ($content | lines)
    
    for line_idx in 0..(($lines | length) - 1) {
        let line = ($lines | get $line_idx)
        let line_num = ($line_idx + 1)
        
        # Check for hardcoded /nix/store paths
        if ($line | str contains "/nix/store/") and not ($line | str trim | str starts-with "#") {
            $issues = ($issues | append {
                file: $file,
                line: $line_num,
                issue: "Hardcoded /nix/store path detected"
            })
        }
        
        # Check for deprecated patterns
        if ($line | str contains "buildInputs = [") and ($line | str contains "pkgs.") {
            $issues = ($issues | append {
                file: $file,
                line: $line_num,
                issue: "Consider using 'with pkgs;' for cleaner syntax"
            })
        }
        
        # Check for missing semicolons (common mistake)
        if ($line | str trim | str ends-with "}") and not ($line | str contains ";") and not ($line | str contains "{") {
            let prev_line = if $line_idx > 0 { $lines | get ($line_idx - 1) } else { "" }
            if not ($prev_line | str trim | str ends-with ";") and not ($prev_line | str trim | str ends-with "{") {
                $issues = ($issues | append {
                    file: $file,
                    line: $line_num,
                    issue: "Possible missing semicolon"
                })
            }
        }
        
        # Check for insecure fetchers
        if ($line | str contains "fetchTarball") and not ($line | str contains "sha256") {
            $issues = ($issues | append {
                file: $file,
                line: $line_num,
                issue: "fetchTarball without sha256 is insecure"
            })
        }
    }
    
    $issues
}

# Main function for CLI usage
def main [
    action: string = "check",  # check or report
    --staged-only = false,
    --verbose = false
] {
    if $action == "check" {
        check_nix_syntax --staged-only=$staged_only --verbose=$verbose
    } else if $action == "report" {
        banner "Nix Syntax Check Report" --context "nix-syntax"
        let files = (glob "**/*.nix")
        info $"Checking ($files | length) Nix files..." --context "nix-syntax"
        check_nix_syntax --verbose=$verbose
    } else {
        error $"Unknown action: ($action). Use: check or report" --context "nix-syntax"
        exit 1
    }
}