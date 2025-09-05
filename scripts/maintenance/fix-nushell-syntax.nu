#!/usr/bin/env nu

# Custom Nushell syntax fixer for common legacy syntax issues
# Based on the patterns we've encountered in the codebase

use ../lib/logging.nu

def main [
    --target-dir: string = "scripts/lib"    # Directory to process
    --dry-run = false                       # Show what would be changed  
    --backup = true                         # Create backups before changing
] {
    print "Nushell Syntax Fixer"
    
    if not ($target_dir | path exists) {
        error $"Target directory does not exist: ($target_dir)"
        return
    }
    
    let nu_files = (glob $"($target_dir)/**/*.nu")
    if ($nu_files | is-empty) {
        print "No .nu files found in target directory"
        return
    }
    
    print $"Found ($nu_files | length) Nushell files to process"
    
    let fixes_applied = ($nu_files | each { | file|
        process_file $file $dry_run $backup
    } | math sum)
    
    print $"Applied ($fixes_applied) fixes total"
}

def process_file [file: string, dry_run: bool, backup: bool] {
    print $"Processing ($file)..."
    
    let content = (open $file)
    mut fixed_content = $content
    mut fixes_count = 0
    
    # Fix 1: Function return type syntax (] { -> ] {)
    let return_type_fixes = ($fixed_content | str replace --all --regex '\] -> [a-zA-Z_<>]+\s*\{' '] {')
    if $return_type_fixes != $fixed_content {
        $fixes_count = $fixes_count + 1
        $fixed_content = $return_type_fixes
        print "Fixed return type syntax"
    }
    
    # Fix 2: Logging function calls without --context flag
    let logging_patterns = [
        'error \$"([^"]*)" "([^"]*)"'
        'warn \$"([^"]*)" "([^"]*)"'  
        'info \$"([^"]*)" "([^"]*)"'
        'debug \$"([^"]*)" "([^"]*)"'
        'success \$"([^"]*)" "([^"]*)"'
    ]
    
    for pattern in $logging_patterns {
        let func_name = ($pattern | str substring 0..($pattern | str index-of ' '))
        let replacement = $'($func_name) $"$1" --context "$2"'
        let new_content = ($fixed_content | str replace --all --regex $pattern $replacement)
        if $new_content != $fixed_content {
            $fixes_count = $fixes_count + 1
            $fixed_content = $new_content
            print $"Fixed ($func_name) function calls"
        }
    }
    
    # Fix 3: let-env to export-env (for top-level assignments)
    let env_fixes = ($fixed_content | str replace --all --regex 'let-env ([A-Z_]+) = ' '$env.$1 = ')
    if $env_fixes != $fixed_content {
        $fixes_count = $fixes_count + 1
        $fixed_content = $env_fixes
        print "Fixed let-env syntax"
    }
    
    # Fix 4: mut keyword issues (mut -> mut)
    let mut_fixes = ($fixed_content | str replace --all 'mut ' 'mut ')
    if $mut_fixes != $fixed_content {
        $fixes_count = $fixes_count + 1
        $fixed_content = $mut_fixes  
        print "Fixed mut keyword syntax"
    }
    
    # Fix 5: Datetime arithmetic (add duration units)
    let datetime_fixes = ($fixed_content | str replace --all --regex '\(date now\) - \(([^)]+)\)' '(date now) - ((((($1) * 1ms) * 1ms) * 1ms) * 1ms)')
    if $datetime_fixes != $fixed_content {
        $fixes_count = $fixes_count + 1
        $fixed_content = $datetime_fixes
        print "Fixed datetime arithmetic"
    }
    
    # Apply changes
    if $fixes_count > 0 {
        if $dry_run {
            print $"[DRY-RUN] Would apply ($fixes_count) fixes to ($file)"
        } else {
            if $backup {
                let backup_file = $"($file).backup"
                $content | save $backup_file
                print $"Created backup: ($backup_file)"
            }
            
            $fixed_content | save --force $file
            print $"Applied ($fixes_count) fixes to ($file)"
        }
    } else {
        print $"No fixes needed for ($file)"
    }
    
    $fixes_count
}

# Additional function to check syntax after fixes
def check_syntax [file: string] {
    let result = (nu --check $file | complete)
    if $result.exit_code == 0 {
        print $"Syntax OK: ($file)"
        true
    } else {
        print $"Syntax errors in ($file):"
        print $result.stderr
        false
    }
}

# Batch syntax check function
def check_all_syntax [target_dir: string = "scripts/lib"] {
    print "Checking Syntax"
    
    let nu_files = (glob $"($target_dir)/**/*.nu")
    let results = ($nu_files | each { | file| 
        {
            file: $file,
            valid: (check_syntax $file)
        }
    })
    
    let valid_files = ($results | where valid == true | length)
    let total_files = ($results | length)
    
    if $valid_files == $total_files {
        print $"All ($total_files) files have valid syntax!"
    } else {
        let invalid_files = ($total_files - $valid_files)
        error $"($invalid_files) of ($total_files) files have syntax errors"
        
        $results | where valid == false | each { | result|
            print $"❌ ($result.file)"
        }
    }
    
    $valid_files == $total_files
}