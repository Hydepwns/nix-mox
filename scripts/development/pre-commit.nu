#!/usr/bin/env nu

# nix-mox Pre-commit Hook
# Runs code quality checks before commits

def main [] {
    print "🔍 nix-mox Pre-commit Checks"
    print "============================"
    
    let start_time = (date now)
    let mut failed_checks = []
    
    # Run essential checks
    print "\n🔍 Running essential checks..."
    
    # Check for TODOs/FIXMEs
    if not (check_todos) {
        $failed_checks = ($failed_checks | append "TODOs/FIXMEs found")
    }
    
    # Check syntax
    if not (check_syntax) {
        $failed_checks = ($failed_checks | append "Syntax errors found")
    }
    
    # Check formatting
    if not (check_formatting) {
        $failed_checks = ($failed_checks | append "Formatting issues found")
    }
    
    # Check security
    if not (check_security) {
        $failed_checks = ($failed_checks | append "Security issues found")
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    # Report results
    if ($failed_checks | length) > 0 {
        print $"\n❌ Pre-commit checks failed in ($duration | into string | str substring 0..8):"
        $failed_checks | each { |check|
            print $"  - $check"
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
    
    let todo_patterns = [
        "TODO"
        "FIXME" 
        "XXX"
        "HACK"
        "BUG"
    ]
    
    let issues = ($todo_patterns | each { |pattern|
        let matches = (grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp 2>/dev/null | lines | length)
        $matches
    } | math sum)
    
    if $issues > 0 {
        print $"    ⚠️  Found $issues TODO/FIXME items"
        false
    } else {
        print "    ✅ No TODOs/FIXMEs found"
        true
    }
}

def check_syntax [] {
    print "  Checking Nix syntax..."
    
    let nix_files = (find . -name "*.nix" -not -path "./.git/*" -not -path "./coverage-tmp/*" -not -path "./tmp/*" | lines)
    let syntax_errors = ($nix_files | each { |file|
        try {
            nix eval --file $file --impure 2>&1 | lines | where ($it | str contains "error:") | length
        } catch {
            0
        }
    } | math sum)
    
    if $syntax_errors > 0 {
        print $"    ❌ Found $syntax_errors syntax errors"
        false
    } else {
        print "    ✅ All Nix files have valid syntax"
        true
    }
}

def check_formatting [] {
    print "  Checking code formatting..."
    
    let nix_files = (find . -name "*.nix" -not -path "./.git/*" -not -path "./coverage-tmp/*" -not -path "./tmp/*" | lines)
    let unformatted = ($nix_files | each { |file|
        let formatted = (nixpkgs-fmt $file 2>/dev/null)
        let original = (open $file)
        if $formatted != $original {
            $file
        }
    } | where ($it != null) | length)
    
    if $unformatted > 0 {
        print $"    ⚠️  Found $unformatted unformatted files"
        print "    💡 Run 'make format' to fix"
        false
    } else {
        print "    ✅ All files are properly formatted"
        true
    }
}

def check_security [] {
    print "  Checking for security issues..."
    
    let security_patterns = [
        "password.*=.*\"[^\"]*\""
        "secret.*=.*\"[^\"]*\""
        "token.*=.*\"[^\"]*\""
        "api_key.*=.*\"[^\"]*\""
        "private_key.*=.*\"[^\"]*\""
    ]
    
    let security_issues = ($security_patterns | each { |pattern|
        let matches = (grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp --exclude="*.md" 2>/dev/null | lines | length)
        $matches
    } | math sum)
    
    if $security_issues > 0 {
        print $"    ⚠️  Found $security_issues potential security issues"
        print "    💡 Consider using environment variables or secrets management"
        false
    } else {
        print "    ✅ No obvious security issues found"
        true
    }
}

# Run the main function
main 