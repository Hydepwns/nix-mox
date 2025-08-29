#!/usr/bin/env nu
# Pre-commit hook for function naming consistency
# Enforces snake_case naming convention across nix-mox

use ../../lib/logging.nu *

# Main function naming check
export def check_function_naming [
    --fix = false,              # Attempt to auto-fix issues
    --staged-only = false       # Only check staged files
] {
    let files_to_check = if $staged_only {
        # Get staged .nu files
        try {
            let staged_files = (git diff --cached --name-only --diff-filter=ACMR | lines | where ($it | str ends-with ".nu"))
            if ($staged_files | length) == 0 {
                success "No .nu files in staging area" --context "function-naming"
                return 0
            }
            $staged_files
        } catch {
            warn "Could not get staged files, checking all .nu files" --context "function-naming"
            (glob "scripts/**/*.nu")
        }
    } else {
        # Check all .nu files in scripts directory
        (glob "scripts/**/*.nu")
    }
    
    let violations = find_naming_violations $files_to_check
    
    if ($violations | length) == 0 {
        success "All functions follow snake_case naming convention! ✅" --context "function-naming"
        return 0
    }
    
    # Report violations
    error $"Found ($violations | length) function naming violations:" --context "function-naming"
    
    let grouped_violations = ($violations | group-by file)
    for file_group in ($grouped_violations | transpose key value) {
        error $"📁 ($file_group.key):" --context "function-naming"
        for violation in $file_group.value {
            error $"  Line ($violation.line): ($violation.function_name) should be ($violation.suggested_name)" --context "function-naming"
        }
    }
    
    if $fix {
        warn "Auto-fixing function names..." --context "function-naming"
        fix_naming_violations $violations
        success "Fixed function naming violations. Please review changes and re-stage." --context "function-naming"
        return 0
    } else {
        error "" --context "function-naming"
        error "Fix these naming issues by:" --context "function-naming"
        error "1. Manual fix: Update function names to use snake_case" --context "function-naming" 
        error "2. Auto-fix: Run 'nu scripts/maintenance/ci/function-naming-check.nu --fix'" --context "function-naming"
        error "" --context "function-naming"
        return 1
    }
}

# Find function naming violations in files
def find_naming_violations [files: list<string>] {
    mut violations = []
    
    for file in $files {
        if not ($file | path exists) {
            continue
        }
        
        let content = (open $file)
        let lines = ($content | lines)
        
        for line_idx in 0..(($lines | length) - 1) {
            let line = ($lines | get $line_idx)
            
            # Check for function definitions with kebab-case
            if ($line | str starts-with "def ") and ($line | str contains "-") and ($line | str contains "[") {
                # Extract function name
                let parts = ($line | str replace "def " "" | split row " ")
                let func_name = ($parts | first)
                
                # Skip if this looks like it's already being processed
                if ($func_name | str contains '_') {
                    continue
                }
                
                # Only flag actual kebab-case functions
                if ($func_name | str contains '-') {
                    let suggested_name = ($func_name | str replace -a '-' '_')
                    $violations = ($violations | append {
                        file: $file,
                        line: ($line_idx + 1),
                        function_name: $func_name,
                        suggested_name: $suggested_name,
                        original_line: $line
                    })
                }
            }
        }
    }
    
    $violations
}

# Fix naming violations automatically
def fix_naming_violations [violations: list] {
    let files_to_fix = ($violations | group-by file)
    
    for file_group in ($files_to_fix | transpose key value) {
        let file_path = $file_group.key
        let file_violations = $file_group.value
        
        info $"Fixing ($file_violations | length) violations in ($file_path)" --context "function-naming"
        
        let content = (open $file_path)
        mut updated_content = $content
        
        for violation in $file_violations {
            # Fix function definition
            $updated_content = ($updated_content | str replace $"def ($violation.function_name)" $"def ($violation.suggested_name)")
            
            # Fix function calls - be conservative to avoid false replacements
            $updated_content = ($updated_content | str replace $"($violation.function_name)(" $"($violation.suggested_name)(")
            $updated_content = ($updated_content | str replace $" ($violation.function_name) " $" ($violation.suggested_name) ")
            $updated_content = ($updated_content | str replace $" ($violation.function_name)\n" $" ($violation.suggested_name)\n")
            
            info $"  ✓ ($violation.function_name) → ($violation.suggested_name)" --context "function-naming"
        }
        
        # Write updated content
        $updated_content | save -f $file_path
    }
}

# Check for other naming inconsistencies beyond functions
export def comprehensive_naming_check [] {
    banner "Comprehensive Naming Consistency Check" --context "function-naming"
    
    # Check function naming
    info "Checking function naming..." --context "function-naming"
    let function_result = (check_function_naming)
    
    # Check for other inconsistencies
    info "Checking for other naming patterns..." --context "function-naming"
    
    # Check for inconsistent variable naming in function signatures
    let files = (glob "scripts/**/*.nu")
    mut other_issues = []
    
    for file in $files {
        let content = (open $file)
        let lines = ($content | lines)
        
        for line_idx in 0..(($lines | length) - 1) {
            let line = ($lines | get $line_idx)
            
            # Check for mixed parameter naming
            if ($line | str starts-with "def ") and ($line | str contains "[") and ($line | str contains "-") {
                $other_issues = ($other_issues | append {
                    file: $file,
                    line: ($line_idx + 1),
                    issue: "kebab-case parameter name",
                    content: $line
                })
            }
        }
    }
    
    if ($other_issues | length) > 0 {
        warn $"Found ($other_issues | length) other naming inconsistencies:" --context "function-naming"
        for issue in $other_issues {
            warn $"  ($issue.file):($issue.line) - ($issue.issue)" --context "function-naming"
        }
    } else {
        success "No other naming inconsistencies found!" --context "function-naming"
    }
    
    return $function_result
}

# Generate a summary report
export def generate_naming_report [] {
    banner "Function Naming Compliance Report" --context "function-naming"
    
    let files = (glob "scripts/**/*.nu")
    info $"Analyzing ($files | length) Nushell scripts..." --context "function-naming"
    
    mut stats = {
        total_functions: 0,
        snake_case_functions: 0,
        kebab_case_functions: 0,
        single_word_functions: 0,
        compliance_percentage: 0
    }
    
    mut all_functions = []
    
    for file in $files {
        let content = (open $file)
        let lines = ($content | lines)
        
        for line in $lines {
            if ($line | str starts-with "def ") and ($line | str contains "[") {
                let parts = ($line | str replace "def " "" | split row " ")
                let func_name = ($parts | first)
                
                $stats.total_functions = ($stats.total_functions + 1)
                
                if ($func_name | str contains '_') {
                    $stats.snake_case_functions = ($stats.snake_case_functions + 1)
                } else if ($func_name | str contains '-') {
                    $stats.kebab_case_functions = ($stats.kebab_case_functions + 1)
                } else {
                    $stats.single_word_functions = ($stats.single_word_functions + 1)
                }
                
                $all_functions = ($all_functions | append {
                    file: $file,
                    name: $func_name,
                    type: (if ($func_name | str contains '_') {
                        "snake_case"
                    } else if ($func_name | str contains '-') {
                        "kebab_case" 
                    } else {
                        "single_word"
                    })
                })
            }
        }
    }
    
    # Calculate compliance percentage
    let compliant_functions = ($stats.snake_case_functions + $stats.single_word_functions)
    $stats.compliance_percentage = (if $stats.total_functions > 0 { 
        ($compliant_functions * 100 / $stats.total_functions) | math round
    } else { 
        100 
    })
    
    # Report statistics
    info "📊 Function Naming Statistics:" --context "function-naming"
    info $"  Total functions: ($stats.total_functions)" --context "function-naming"
    info $"  ✅ snake_case: ($stats.snake_case_functions)" --context "function-naming"
    info $"  ✅ single-word: ($stats.single_word_functions)" --context "function-naming"
    info $"  ❌ kebab-case: ($stats.kebab_case_functions)" --context "function-naming"
    info $"  🎯 Compliance: ($stats.compliance_percentage)%" --context "function-naming"
    
    if $stats.kebab_case_functions > 0 {
        warn "Functions needing updates:" --context "function-naming"
        let kebab_functions = ($all_functions | where type == "kebab_case")
        for func in $kebab_functions {
            let suggested = ($func.name | str replace -a '-' '_')
            warn $"  ($func.file): ($func.name) → ($suggested)" --context "function-naming"
        }
    }
    
    return $stats
}

# Main function for CLI usage
def main [
    action: string = "check",  # check, fix, comprehensive, report
    --staged-only = false,     # Only check staged files
    --exit-code = true         # Return appropriate exit code
] {
    let result = if $action == "check" {
        if $staged_only {
            check_function_naming --staged-only=true
        } else {
            check_function_naming --staged-only=false
        }
    } else if $action == "fix" {
        if $staged_only {
            check_function_naming --fix=true --staged-only=true
        } else {
            check_function_naming --fix=true --staged-only=false
        }
    } else if $action == "comprehensive" {
        comprehensive_naming_check
    } else if $action == "report" {
        generate_naming_report
        0
    } else {
        error $"Unknown action: ($action). Use: check, fix, comprehensive, report" --context "function-naming"
        1
    }
    
    if $exit_code {
        exit $result
    } else {
        $result
    }
}