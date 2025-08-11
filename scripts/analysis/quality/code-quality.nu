#!/usr/bin/env nu

# nix-mox Code Quality Analysis Script
# Analyzes code quality and suggests improvements
use ../lib/common.nu

def check_nix_syntax [] {
    common log_info "Checking Nix syntax..."
    let nix_files = (ls **/*.nix | get name)
    mut results = []
    for file in $nix_files {
        let result = (try {
            nix eval --file $file --impure --json
            {file: $file, status: "valid", error: null}
        } catch {
            {file: $file, status: "invalid", error: "Syntax error"}
        })
        $results = ($results | append $result)
    }
    $results
}

def check_nushell_syntax [] {
    common log_info "Checking Nushell syntax..."
    let nu_files = (ls **/*.nu | get name)
    mut results = []
    for file in $nu_files {
        let result = (try {
            nu -c $"source ($file)"
            {file: $file, status: "valid", error: null}
        } catch {
            {file: $file, status: "invalid", error: "Syntax error"}
        })
        $results = ($results | append $result)
    }
    $results
}

def check_file_consistency [] {
    common log_info "Checking file consistency..."
    mut issues = []

    # Check for consistent line endings (simplified check)
    let all_files = ((ls **/*.nix | get name) | append (ls **/*.nu | get name) | append (ls **/*.sh | get name))

    # Check for trailing whitespace
    for file in $all_files {
        let content = (open --raw $file)
        if ($content | str ends-with " ") {
            $issues = ($issues | append $"File ($file) has trailing whitespace")
        }
    }

    # Check for missing shebangs in scripts
    let script_files = ((ls **/*.nu | get name) | append (ls **/*.sh | get name))
    for file in $script_files {
        let first_line = (open --raw $file | lines | first | str trim)
        if not ($first_line | str starts-with "#!") {
            $issues = ($issues | append $"Script file ($file) missing shebang")
        }
    }
    $issues
}

def check_documentation_coverage [] {
    common log_info "Checking documentation coverage..."
    mut issues = []

    # Check for README files
    let readme_files = (ls **/README* | get name)
    if ($readme_files | length) < 3 {
        $issues = ($issues | append "Limited README coverage - consider adding more documentation")
    }

    # Check for inline documentation
    let nu_files = (ls **/*.nu | get name)
    for file in $nu_files {
        let content = (open --raw $file)
        if not ($content | str contains "#") {
            $issues = ($issues | append $"File ($file) has no comments")
        }
    }
    $issues
}

def check_security_issues [] {
    common log_info "Checking for security issues..."
    mut issues = []

    # Check for hardcoded secrets (simplified)
    let all_files = ((ls **/*.nix | get name) | append (ls **/*.nu | get name) | append (ls **/*.sh | get name))
    for file in $all_files {
        let content = (open --raw $file)
        if ($content | str contains "password =") or ($content | str contains "secret =") {
            $issues = ($issues | append $"Potential hardcoded secret in ($file)")
        }
    }
    $issues
}

def check_performance_issues [] {
    common log_info "Checking for performance issues..."
    mut issues = []

    # Check for large files
    let all_files = (ls **/* | get name)
    for file in $all_files {
        let file_info = (ls $file)
        if not ($file_info | is-empty) {
            let size = ($file_info | get size | first | into int)
            if $size > 1048576 {  # 1MB
                $issues = ($issues | append $"Large file ($file) - consider if it should be in version control")
            }
        }
    }
    $issues
}

def generate_quality_report [nix_results: list, nu_results: list, consistency_issues: list, doc_issues: list, security_issues: list, perf_issues: list] {
    let total_files = (($nix_results | length) + ($nu_results | length))
    let invalid_files = (($nix_results | where status == "invalid" | length) + ($nu_results | where status == "invalid" | length))
    let total_issues = (($consistency_issues | length) + ($doc_issues | length) + ($security_issues | length) + ($perf_issues | length))
    let quality_score = if $total_files == 0 {
        100
    } else {
        (100 - (($invalid_files | into float) / ($total_files | into float) * 100))
    }

    {
        timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
        summary: {
            total_files: $total_files
            invalid_files: $invalid_files
            quality_score: $quality_score
            total_issues: $total_issues
        }
        syntax_check: {
            nix_files: $nix_results
            nushell_files: $nu_results
        }
        issues: {
            consistency: $consistency_issues
            documentation: $doc_issues
            security: $security_issues
            performance: $perf_issues
        }
        recommendations: (generate_recommendations $invalid_files $total_issues $quality_score)
    }
}

def generate_recommendations [invalid_files: int, total_issues: int, quality_score: float] {
    mut recommendations = []

    if $invalid_files > 0 {
        $recommendations = ($recommendations | append "Fix syntax errors in files")
    }

    if $total_issues > 10 {
        $recommendations = ($recommendations | append "Address code quality issues")
    }

    if $quality_score < 80 {
        $recommendations = ($recommendations | append "Improve overall code quality")
    }

    if ($recommendations | is-empty) {
        $recommendations = ($recommendations | append "Code quality is good - maintain current standards")
    }

    $recommendations
}

def display_quality_report [report: record] {
    print $"($env.GREEN)=== nix-mox Code Quality Report === ($env.NC)"
    print $"Generated: ($report.timestamp)"
    print ""

    let summary = $report.summary
    print $"($env.BLUE)Summary:($env.NC)"
    print $"  Total Files: ($summary.total_files)"
    print $"  Invalid Files: ($summary.invalid_files)"
    print $"  Quality Score: ($summary.quality_score | into int)%"
    print $"  Total Issues: ($summary.total_issues)"
    print ""

    # Show syntax errors
    let nix_errors = ($report.syntax_check.nix_files | where status == "invalid")
    let nu_errors = ($report.syntax_check.nushell_files | where status == "invalid")

    if not ($nix_errors | is-empty) {
        print $"($env.RED)Nix Syntax Errors:($env.NC)"
        for error in $nix_errors {
            print $"  ($error.file): ($error.error)"
        }
        print ""
    }

    if not ($nu_errors | is-empty) {
        print $"($env.RED)Nushell Syntax Errors:($env.NC)"
        for error in $nu_errors {
            print $"  ($error.file): ($error.error)"
        }
        print ""
    }

    # Show issues by category
    let issues = $report.issues

    if not ($issues.consistency | is-empty) {
        print $"($env.YELLOW)Consistency Issues:($env.NC)"
        for issue in $issues.consistency {
            print $"  • ($issue)"
        }
        print ""
    }

    if not ($issues.documentation | is-empty) {
        print $"($env.YELLOW)Documentation Issues:($env.NC)"
        for issue in $issues.documentation {
            print $"  • ($issue)"
        }
        print ""
    }

    if not ($issues.security | is-empty) {
        print $"($env.RED)Security Issues:($env.NC)"
        for issue in $issues.security {
            print $"  • ($issue)"
        }
        print ""
    }

    if not ($issues.performance | is-empty) {
        print $"($env.YELLOW)Performance Issues:($env.NC)"
        for issue in $issues.performance {
            print $"  • ($issue)"
        }
        print ""
    }

    print $"($env.GREEN)Recommendations:($env.NC)"
    for rec in $report.recommendations {
        print $"  • ($rec)"
    }
    print ""
}

def main [] {
    print "🔍 nix-mox Code Quality Analysis"
    print "================================"

    let start_time = (date now)

    # Run all quality checks
    let nix_results = (check_nix_syntax)
    let nu_results = (check_nushell_syntax)
    let consistency_issues = (check_file_consistency)
    let doc_issues = (check_documentation_coverage)
    let security_issues = (check_security_issues)
    let perf_issues = (check_performance_issues)

    # Generate and display report
    let report = (generate_quality_report $nix_results $nu_results $consistency_issues $doc_issues $security_issues $perf_issues)
    display_quality_report $report

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    print $"\n✅ Code quality analysis completed in ($duration | into string | str substring 0..8)"
    print "\n📋 Summary:"
    print "- Run 'make format' to fix formatting issues"
    print "- Address TODOs and FIXMEs before production"
    print "- Review security findings"
    print "- Update documentation as needed"
}

def check_todos [] {
    print "\n🔍 Checking for TODOs, FIXMEs, and HACKs..."
    let todo_patterns = ["TODO", "FIXME", "XXX", "HACK", "BUG", "NOTE:"]
    let issues = ($todo_patterns | each { |pattern|
        let matches = (grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp out+err> /dev/null | lines | each { |line|
            let parts = ($line | split row ":")
            if ($parts | length) >= 3 {
                {
                    file: $parts.0
                    line: $parts.1
                    pattern: $pattern
                    context: ($parts | skip 2 | str join ":")
                }
            }
        })
        $matches
    } | flatten)

    if ($issues | length) > 0 {
        print $"\n⚠️  Found ($issues | length) TODO/FIXME items:"
        $issues | each { |issue|
            print $"  ($issue.file):($issue.line) - ($issue.pattern) ($issue.context)"
        }
    } else {
        print "✅ No TODOs or FIXMEs found"
    }
}

def check_syntax [] {
    print "\n🔍 Checking Nix syntax..."
    let nix_files = (ls **/*.nix | where name !~ '.git' and name !~ 'coverage-tmp' and name !~ 'tmp' | get name)
    let syntax_errors = ($nix_files | each { |file|
        try {
            nix eval --file $file --impure out+err> /dev/null | lines | where ($it | str contains "error:")
        } catch {
            []
        }
    } | flatten)

    if ($syntax_errors | length) > 0 {
        print $"\n❌ Found ($syntax_errors | length) syntax errors:"
        $syntax_errors | each { |error|
            print $"  $error"
        }
    } else {
        print "✅ All Nix files have valid syntax"
    }
}

def check_formatting [] {
    print "\n🔍 Checking code formatting..."

    # Check if nixpkgs-fmt is available
    let nixpkgs_fmt_available = (which nixpkgs-fmt | length) > 0
    if not $nixpkgs_fmt_available {
        print "⚠️  nixpkgs-fmt not found - skipping formatting check"
        print "💡 Install nixpkgs-fmt: nix profile install nixpkgs#nixpkgs-fmt"
        return
    }

    let nix_files = (ls **/*.nix | where name !~ '.git' and name !~ 'coverage-tmp' and name !~ 'tmp' | get name)
    let unformatted = ($nix_files | each { |file|
        let formatted = (nixpkgs-fmt $file out+err> /dev/null)
        let original = (open $file)
        if $formatted != $original {
            $file
        }
    } | where ($it != null))

    if ($unformatted | length) > 0 {
        print $"\n⚠️  Found ($unformatted | length) unformatted files:"
        $unformatted | each { |unformatted_file|
            print $"  $unformatted_file"
        }
        print "\n💡 Run 'make format' to fix formatting"
    } else {
        print "✅ All files are properly formatted"
    }
}

def check_security [] {
    print "\n🔍 Checking for security issues..."
    let security_patterns = [
        "password.*=.*\"[^\"]*\"",
        "secret.*=.*\"[^\"]*\"",
        "token.*=.*\"[^\"]*\"",
        "api_key.*=.*\"[^\"]*\"",
        "private_key.*=.*\"[^\"]*\""
    ]
    let security_issues = ($security_patterns | each { |pattern|
        let matches = (grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp --exclude="*.md" out+err> /dev/null | lines | each { |line|
            let parts = ($line | split row ":")
            if ($parts | length) >= 3 {
                {
                    file: $parts.0
                    line: $parts.1
                    pattern: $pattern
                    context: ($parts | skip 2 | str join ":")
                }
            }
        })
        $matches
    } | flatten)

    if ($security_issues | length) > 0 {
        print $"\n⚠️  Found ($security_issues | length) potential security issues:"
        $security_issues | each { |issue|
            print $"  ($issue.file):($issue.line) - Potential hardcoded secret"
        }
        print "\n💡 Consider using environment variables or secrets management"
    } else {
        print "✅ No obvious security issues found"
    }
}

def check_documentation [] {
    print "\n🔍 Checking documentation..."
    let doc_files = (ls docs/**/*.md | get name)
    let readme_files = (ls **/README.md | where name !~ '.git' | get name)
    let all_docs = ($doc_files | append $readme_files)

    let outdated_docs = ($all_docs | each { |file|
        let content = (open $file)
        let outdated_patterns = [
            "setup-wizard",
            "setup-personal",
            "setup-gaming-wizard",
            "setup-gaming-workstation"
        ]

        let has_outdated = ($outdated_patterns | any { |pattern|
            $content | str contains $pattern
        })

        if $has_outdated {
            $file
        }
    } | where ($it != null))

    if ($outdated_docs | length) > 0 {
        print $"\n⚠️  Found ($outdated_docs | length) potentially outdated documentation files:"
        $outdated_docs | each { |f| print $"  ($f)" }
        print "\n💡 Update documentation to reference new unified setup script"
    } else {
        print "✅ Documentation appears up to date"
    }
}

def check_performance [] {
    print "\n🔍 Checking for performance issues..."
    let performance_patterns = [
        "nix build.*--rebuild",
        "nix-collect-garbage.*-d",
        "rm -rf.*nix/store"
    ]
    let performance_issues = ($performance_patterns | each { |pattern|
        let matches = (grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp out+err> /dev/null | lines | each { |line|
            let parts = ($line | split row ":")
            if ($parts | length) >= 3 {
                {
                    file: $parts.0
                    line: $parts.1
                    pattern: $pattern
                    context: ($parts | skip 2 | str join ":")
                }
            }
        })
        $matches
    } | flatten)

    if ($performance_issues | length) > 0 {
        print $"\n⚠️  Found ($performance_issues | length) potential performance issues:"
        $performance_issues | each { |issue|
            print $"  ($issue.file):($issue.line) - Potentially expensive operation"
        }
        print "\n💡 Consider optimizing expensive operations"
    } else {
        print "✅ No obvious performance issues found"
    }
}

# Export functions for use in other scripts
export def analyze [] {
    main
}

export def check-syntax [] {
    let nix_results = (check_nix_syntax)
    let nu_results = (check_nushell_syntax)

    print "Syntax Check Results:"
    print "===================="

    let nix_errors = ($nix_results | where status == "invalid")
    let nu_errors = ($nu_results | where status == "invalid")

    if ($nix_errors | is-empty) and ($nu_errors | is-empty) {
        print "✅ All files have valid syntax"
    } else {
        if not ($nix_errors | is-empty) {
            print "❌ Nix syntax errors:"
            for error in $nix_errors {
                print $"  ($error.file): ($error.error)"
            }
        }
        if not ($nu_errors | is-empty) {
            print "❌ Nushell syntax errors:"
            for error in $nu_errors {
                print $"  ($error.file): ($error.error)"
            }
        }
    }
}

export def check-security [] {
    let security_issues = (check_security_issues)

    if ($security_issues | is-empty) {
        print "✅ No security issues found"
    } else {
        print "⚠️ Security issues found:"
        for issue in $security_issues {
            print $"  • ($issue)"
        }
    }
}
