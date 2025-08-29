#!/usr/bin/env nu
# Nushell syntax validation pre-commit hook
# Validates all .nu files for correct syntax

use ../../lib/logging.nu *

# Main syntax check function
export def check_syntax [
    --staged-only = false,      # Only check staged files
    --verbose = false           # Show verbose output
] {
    let files_to_check = if $staged_only {
        # Get staged .nu files
        try {
            let staged_files = (git diff --cached --name-only --diff-filter=ACMR | lines | where ($it | str ends-with ".nu"))
            if ($staged_files | length) == 0 {
                success "No .nu files in staging area" --context "nu-syntax"
                return 0
            }
            $staged_files
        } catch {
            warn "Could not get staged files, checking all .nu files" --context "nu-syntax"
            (glob "scripts/**/*.nu")
        }
    } else {
        # Check all .nu files in scripts directory
        (glob "scripts/**/*.nu")
    }
    
    mut errors = []
    mut warnings = []
    
    for file in $files_to_check {
        if not ($file | path exists) {
            continue
        }
        
        if $verbose {
            info $"Checking ($file)..." --context "nu-syntax"
        }
        
        # Check syntax by attempting to parse the file
        let result = (nu --ide-check 10 $file | complete)
        
        if $result.exit_code != 0 {
            $errors = ($errors | append {
                file: $file,
                error: $result.stderr
            })
        } else {
            # Additional checks for common issues
            let content = (open $file)
            
            # Check for common syntax issues
            let checks = check_common_issues $file $content
            if ($checks | length) > 0 {
                $warnings = ($warnings | append $checks)
            }
        }
    }
    
    # Report results
    if ($errors | length) == 0 and ($warnings | length) == 0 {
        success $"All ($files_to_check | length) Nushell files have valid syntax! ✅" --context "nu-syntax"
        return 0
    }
    
    if ($errors | length) > 0 {
        error $"Found ($errors | length) syntax errors:" --context "nu-syntax"
        for err in $errors {
            error $"  📁 ($err.file):" --context "nu-syntax"
            error $"    ($err.error)" --context "nu-syntax"
        }
    }
    
    if ($warnings | length) > 0 {
        warn $"Found ($warnings | length) potential issues:" --context "nu-syntax"
        for warning in $warnings {
            warn $"  📁 ($warning.file):($warning.line)" --context "nu-syntax"
            warn $"    ($warning.issue)" --context "nu-syntax"
        }
    }
    
    if ($errors | length) > 0 {
        return 1
    } else {
        return 0
    }
}

# Check for common Nushell issues
def check_common_issues [file: string, content: string] {
    mut issues = []
    let lines = ($content | lines)
    
    for line_idx in 0..(($lines | length) - 1) {
        let line = ($lines | get $line_idx)
        let line_num = ($line_idx + 1)
        
        # Check for deprecated syntax patterns
        if ($line | str contains "| get 0") {
            $issues = ($issues | append {
                file: $file,
                line: $line_num,
                issue: "Consider using 'first' instead of 'get 0'"
            })
        }
        
        # Check for missing space after pipe
        if ($line | str contains "|" ) and ($line | str contains "|[a-zA-Z]") {
            $issues = ($issues | append {
                file: $file,
                line: $line_num,
                issue: "Missing space after pipe operator"
            })
        }
        
        # Check for incorrect variable syntax
        if ($line | str contains "$(" ) and not ($line | str contains "$(") {
            $issues = ($issues | append {
                file: $file,
                line: $line_num,
                issue: "Possible incorrect variable interpolation"
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
        check_syntax --staged-only=$staged_only --verbose=$verbose
    } else if $action == "report" {
        banner "Nushell Syntax Check Report" --context "nu-syntax"
        let files = (glob "scripts/**/*.nu")
        info $"Checking ($files | length) Nushell files..." --context "nu-syntax"
        check_syntax --verbose=$verbose
    } else {
        error $"Unknown action: ($action). Use: check or report" --context "nu-syntax"
        exit 1
    }
}