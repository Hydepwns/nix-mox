#!/usr/bin/env nu

# nix-mox Pre-commit Hook
# Runs code quality checks before commits

use ../../lib/validators.nu *
use ../../lib/logging.nu *

def main [] {
    banner "nix-mox Pre-commit Checks" --context "pre-commit"

    let start_time = (date now)
    mut failed_checks = []

    # Run essential checks
    info "Running essential checks..." --context "pre-commit"

    # Check for TODOs/FIXMEs (warning only)
    let todo_result = (check_todos)
    if not $todo_result {
        warn "TODO/FIXME check failed (warning only - not blocking commit)" --context "pre-commit"
    }

    # Check syntax
    if not (check_syntax) {
        $failed_checks = ($failed_checks | append "Syntax errors found")
    }

    # Check formatting
    if not (check_formatting) {
        $failed_checks = ($failed_checks | append "Formatting issues found")
    }

    # Check security (warning only)
    let security_result = (check_security)
    if not $security_result {
        print "  ⚠️  Security check failed (warning only - not blocking commit)"
    }

    # Check for banned terminology
    if not (check_banned_names) {
        $failed_checks = ($failed_checks | append "Banned terminology found")
    }

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    # Report results
    if ($failed_checks | length) > 0 {
        print $"\n❌ Pre-commit checks failed in ($duration | into string | str substring 0..8):"
        $failed_checks | each { |check|
            print $"  - ($check)"
        }
        print "\n💡 Fix the issues above before committing"
        print "   Run 'make code-quality' for detailed analysis"
        exit 1
    } else {
        print $"\n✅ All pre-commit checks passed in ($duration | into string | str substring 0..8)"
        print "🚀 Ready to commit!"
    }
}

def check_todos [] {
    print "  Checking for TODOs/FIXMEs..."
    let todo_patterns = ["TODO", "FIXME", "XXX", "HACK", "BUG"]
    let issues = ($todo_patterns | each { |pattern|
        let matches = (try {
            do { grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp } | complete | get stdout | lines | length
        } catch {
            0
        })
        $matches
    } | math sum)

    if $issues > 0 {
        print $"    ⚠️  Found ($issues) TODO/FIXME items"
        false
    } else {
        print "    ✅ No TODOs/FIXMEs found"
        true
    }
}

def check_syntax [] {
    print "  Checking Nix syntax..."
    let nix_files = (ls **/*.nix | get name)

    let syntax_errors = ($nix_files | each { |file|
        try {
            let result = (do { nix eval --file $file --impure --extra-experimental-features "flakes nix-command" } | complete)
            if $result.exit_code != 0 {
                ($result.stderr | lines | where ($it | str contains "error:") | length)
            } else {
                0
            }
        } catch {
            0
        }
    } | math sum)

    if $syntax_errors > 0 {
        print $"    ❌ Found ($syntax_errors) syntax errors"
        false
    } else {
        print "    ✅ All Nix files have valid syntax"
        true
    }
}

def check_formatting [] {
    print "  Checking code formatting..."
    
    let result = (do { 
        treefmt --fail-on-change
    } | complete)
    
    if $result.exit_code == 0 {
        print "    ✅ All files are properly formatted"
        true
    } else {
        print "    ⚠️  Found unformatted files"
        print "    💡 Run 'make format' to fix"
        false
    }
}

def check_security [] {
    print "  Checking for security issues..."
    let security_patterns = [
        "password.*=.*\"[^\"]*\"",
        "secret.*=.*\"[^\"]*\"",
        "token.*=.*\"[^\"]*\"",
        "api_key.*=.*\"[^\"]*\"",
        "private_key.*=.*\"[^\"]*\""
    ]

    let security_issues = ($security_patterns | each { |pattern|
        try {
            do { grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp --exclude="*.md" } | complete | get stdout | lines | length
        } catch {
            0
        }
    } | math sum)

    if $security_issues > 0 {
        print $"    ⚠️  Found ($security_issues) potential security issues"
        print "    💡 Consider using environment variables or secrets management"
        false
    } else {
        print "    ✅ No obvious security issues found"
        true
    }
}

def check_banned_names [] {
    print "  Checking for inclusive terminology..."
    
    # Define banned terms and their suggested replacements
    let banned_terms = [
        {term: "master", suggest: "main, primary, leader"},
        {term: "slave", suggest: "replica, follower, secondary"},
        {term: "whitelist", suggest: "allowlist, safelist"},
        {term: "blacklist", suggest: "blocklist, denylist"},
        {term: "dummy", suggest: "placeholder, sample"},
        {term: "sanity", suggest: "consistency, validity"}
    ]
    
    let issues_found = ($banned_terms | each { |term_info|
        let pattern = $term_info.term
        let files_with_term = (try {
            do { grep -r -l -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp --exclude-dir=result --exclude-dir=.direnv --exclude-dir=node_modules --exclude="*.md" --exclude="CLAUDE.md" --exclude="*.log" --exclude="*.lock" --exclude="pre-commit.nu" } | complete
        } catch {
            {exit_code: 1, stdout: ""}
        })
        
        if $files_with_term.exit_code == 0 and ($files_with_term.stdout | str trim) != "" {
            let file_list = ($files_with_term.stdout | lines)
            let count = ($file_list | length)
            if $count > 0 {
                {
                    term: $pattern
                    count: $count
                    suggest: $term_info.suggest
                    files: ($file_list | first 3 | str join ", ")
                }
            } else {
                null
            }
        } else {
            null
        }
    } | where $it != null)
    
    if ($issues_found | length) > 0 {
        print "    ❌ Found non-inclusive terminology:"
        for issue in $issues_found {
            print $"      • '($issue.term)' found in ($issue.count) file\(s\)"
            print $"        Suggested: ($issue.suggest)"
            if $issue.count <= 3 {
                print $"        Files: ($issue.files)"
            } else {
                print $"        Files: ($issue.files), ..."
            }
        }
        print "    💡 Please update to use inclusive terminology"
        false
    } else {
        print "    ✅ All terminology is inclusive"
        true
    }
}

# Run the main function
main
