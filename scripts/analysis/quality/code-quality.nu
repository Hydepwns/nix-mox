#!/usr/bin/env nu

# nix-mox Code Quality Analysis Script
# Analyzes code quality and suggests improvements

def check_nix_syntax [] {
    info "Checking Nix syntax..." --context "code-quality"
    let nix_files = (ls **/*.nix | get name)
    let results = []
    for file in $nix_files {
        let result = (try {
            nix eval --file $file --impure --json
            {file: $file, status: "valid", error: null}
        } catch {
            {file: $file, status: "invalid", error: "Syntax error"}
        })
        let results = ($results | append $result)
    }
    $results
}

def check_nushell_syntax [] {
    info "Checking Nushell syntax..." --context "code-quality"
    let nu_files = (ls **/*.nu | get name)
    let results = []
    for file in $nu_files {
        let result = (try {
            nu -c $"source ($file)"
            {file: $file, status: "valid", error: null}
        } catch {
            {file: $file, status: "invalid", error: "Syntax error"}
        })
        let results = ($results | append $result)
    }
    $results
}

def validate_file_consistency [] {
    info "Checking file consistency..." --context "code-quality"
    let issues = []

    # Check for consistent line endings (simplified check)
    let all_files = ((ls **/*.nix | get name) | append (ls **/*.nu | get name) | append (ls **/*.sh | get name))

    # Check for trailing whitespace
    for file in $all_files {
        let content = (open --raw $file)
        if ($content | str ends-with " ") {
            let issues = ($issues | append $"File ($file) has trailing whitespace")
        }
    }

    # Check for missing shebangs in scripts
    let script_files = ((ls **/*.nu | get name) | append (ls **/*.sh | get name))
    for file in $script_files {
        let first_line = (open --raw $file | lines | first | str trim)
        if not ($first_line | str starts-with "#!") {
            let issues = ($issues | append $"Script file ($file) missing shebang")
        }
    }
    $issues
}

def check_documentation_coverage [] {
    info "Checking documentation coverage..." --context "code-quality"
    let issues = []

    # Check for README files
    let readme_files = (ls **/README* | get name)
    if ($readme_files | length) < 3 {
        let issues = ($issues | append "Limited README coverage - consider adding more documentation")
    }

    # Check for inline documentation
    let nu_files = (ls **/*.nu | get name)
    for file in $nu_files {
        let content = (open --raw $file)
        if not ($content | str contains "#") {
            let issues = ($issues | append $"File ($file) has no comments")
        }
    }
    $issues
}

def check_security_issues [] {
    info "Checking for security issues..." --context "code-quality"
    let issues = []

    # Check for hardcoded secrets (simplified)
    let all_files = ((ls **/*.nix | get name) | append (ls **/*.nu | get name) | append (ls **/*.sh | get name))
    for file in $all_files {
        let content = (open --raw $file)
        if ($content | str contains "password =") or ($content | str contains "secret =") {
            let issues = ($issues | append $"Potential hardcoded secret in ($file)")
        }
    }
    $issues
}

def check_performance_issues [] {
    info "Checking for performance issues..." --context "code-quality"
    let issues = []

    # Check for large files
    let all_files = (ls **/* | get name)
    for file in $all_files {
        let file_info = (ls $file)
        if not ($file_info | is-empty) {
            let size = ($file_info | get size | first | into int)
            if $size > 1048576 {  # 1MB
                let issues = ($issues | append $"Large file ($file) - consider if it should be in version control")
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
    let recommendations = []

    if $invalid_files > 0 {
        let recommendations = ($recommendations | append "Fix syntax errors in files")
    }

    if $total_issues > 10 {
        let recommendations = ($recommendations | append "Address code quality issues")
    }

    if $quality_score < 80 {
        let recommendations = ($recommendations | append "Improve overall code quality")
    }

    if ($recommendations | is-empty) {
        let recommendations = ($recommendations | append "Code quality is good - maintain current standards")
    }

    $recommendations
}

def display_quality_report [report: record] {
    print $"(ansi green)=== nix-mox Code Quality Report === (ansi reset)"
    print $"Generated: ($report.timestamp)"
    print ""

    let summary = $report.summary
    print $"(ansi blue)Summary:(ansi reset)"
    print $"  Total Files: ($summary.total_files)"
    print $"  Invalid Files: ($summary.invalid_files)"
    print $"  Quality Score: ($summary.quality_score | into int)%"
    print $"  Total Issues: ($summary.total_issues)"
    print ""

    # Show syntax errors
    let nix_errors = ($report.syntax_check.nix_files | where status == "invalid")
    let nu_errors = ($report.syntax_check.nushell_files | where status == "invalid")

    if not ($nix_errors | is-empty) {
        print $"(ansi red)Nix Syntax Errors:(ansi reset)"
        for error in $nix_errors {
            print $"  ($error.file): ($error.error)"
        }
        print ""
    }

    if not ($nu_errors | is-empty) {
        print $"(ansi red)Nushell Syntax Errors:(ansi reset)"
        for error in $nu_errors {
            print $"  ($error.file): ($error.error)"
        }
        print ""
    }

    # Show issues by category
    let issues = $report.issues

    if not ($issues.consistency | is-empty) {
        print $"(ansi yellow)Consistency Issues:(ansi reset)"
        for issue in $issues.consistency {
            print $"  • ($issue)"
        }
        print ""
    }

    if not ($issues.documentation | is-empty) {
        print $"(ansi yellow)Documentation Issues:(ansi reset)"
        for issue in $issues.documentation {
            print $"  • ($issue)"
        }
        print ""
    }

    if not ($issues.security | is-empty) {
        print $"(ansi red)Security Issues:(ansi reset)"
        for issue in $issues.security {
            print $"  • ($issue)"
        }
        print ""
    }

    if not ($issues.performance | is-empty) {
        print $"(ansi yellow)Performance Issues:(ansi reset)"
        for issue in $issues.performance {
            print $"  • ($issue)"
        }
        print ""
    }

    print $"(ansi green)Recommendations:(ansi reset)"
    for rec in $report.recommendations {
        print $"  • ($rec)"
    }
    print ""
}

def main_code_quality [] {
    print $"(ansi blue)🔍 nix-mox Code Quality Analysis(ansi reset)"
    print "================================"

    let start_time = (date now)

    # Run all quality checks
    let nix_results = (check_nix_syntax)
    let nu_results = (check_nushell_syntax)
    let consistency_issues = (validate_file_consistency)
    let doc_issues = (check_documentation_coverage)
    let security_issues = (check_security_issues)
    let perf_issues = (check_performance_issues)

    # Generate and display report
    let report = (generate_quality_report $nix_results $nu_results $consistency_issues $doc_issues $security_issues $perf_issues)
    display_quality_report $report

    let end_time = (date now)
    let duration = ($end_time - $start_time)

    print $"\n(ansi green)✅ Code quality analysis completed in ($duration | into string | str substring 0..8)(ansi reset)"
    print "\n📋 Summary:"
    print $"- Run 'make format' to fix formatting issues"
    print $"- Address TODOs and FIXMEs before production"
    print $"- Review security findings"
    print $"- Update documentation as needed"
}

def check_todos_issues [] {
    print $"\n(ansi blue)🔍 Checking for TODOs, FIXMEs, and HACKs...(ansi reset)"
    let todo_patterns = ["TODO", "FIXME", "XXX", "HACK", "BUG", "NOTE:"]
    let issues = ($todo_patterns | each { | pattern|
        let matches = (grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp out+err> /dev/null | lines | each { | line|
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
        print $"\n(ansi yellow)⚠️  Found ($issues | length) TODO/FIXME items:(ansi reset)"
        $issues | each { | issue|
            print $"  ($issue.file):($issue.line) - ($issue.pattern) ($issue.context)"
        }
    } else {
        print $"(ansi green)✅ No TODOs or FIXMEs found(ansi reset)"
    }
}

def check_syntax_issues [] {
    print $"\n(ansi blue)🔍 Checking Nix syntax...(ansi reset)"
    let nix_files = (ls **/*.nix | where name !~ '.git' and name !~ 'coverage-tmp' and name !~ 'tmp' | get name)
    let syntax_errors = ($nix_files | each { | file|
        try {
            nix eval --file $file --impure out+err> /dev/null | lines | where ($it | str contains "error:")
        } catch {
            []
        }
    } | flatten)

    if ($syntax_errors | length) > 0 {
        print $"\n(ansi red)❌ Found ($syntax_errors | length) syntax errors:(ansi reset)"
        $syntax_errors | each { | error|
            print $"  $error"
        }
    } else {
        print $"(ansi green)✅ All Nix files have valid syntax(ansi reset)"
    }
}

def check_formatting_issues [] {
    print $"\n(ansi blue)🔍 Checking code formatting...(ansi reset)"

    # Check if nixpkgs-fmt is available
    let nixpkgs_fmt_available = (which nixpkgs-fmt | length) > 0
    if not $nixpkgs_fmt_available {
        print $"(ansi yellow)⚠️  nixpkgs-fmt not found - skipping formatting check(ansi reset)"
        print "💡 Install nixpkgs-fmt: nix profile install nixpkgs#nixpkgs-fmt"
        return
    }

    let nix_files = (ls **/*.nix | where name !~ '.git' and name !~ 'coverage-tmp' and name !~ 'tmp' | get name)
    let unformatted = ($nix_files | each { | file|
        let formatted = (nixpkgs-fmt $file out+err> /dev/null)
        let original = (open $file)
        if $formatted != $original {
            $file
        }
    } | where ($it != null))

    if ($unformatted | length) > 0 {
        print $"\n⚠️  Found ($unformatted | length) unformatted files:"
        $unformatted | each { | unformatted_file|
            print $"  $unformatted_file"
        }
        print $"\n(ansi yellow)💡 Run 'make format' to fix formatting(ansi reset)"
    } else {
        print $"(ansi green)✅ All files are properly formatted(ansi reset)"
    }
}

def check_security_issues_code_quality [] {
    print $"\n(ansi blue)🔍 Checking for security issues...(ansi reset)"
    let security_patterns = [
        "password.*=.*\"[^\"]*\"",
        "secret.*=.*\"[^\"]*\"",
        "token.*=.*\"[^\"]*\"",
        "api_key.*=.*\"[^\"]*\"",
        "private_key.*=.*\"[^\"]*\""
    ]
    let security_issues = ($security_patterns | each { | pattern|
        let matches = (grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp --exclude="*.md" out+err> /dev/null | lines | each { | line|
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
        print $"\n(ansi yellow)⚠️  Found ($security_issues | length) potential security issues:(ansi reset)"
        $security_issues | each { | issue|
            print $"  ($issue.file):($issue.line) - Potential hardcoded secret"
        }
        print $"\n(ansi yellow)💡 Consider using environment variables or secrets management(ansi reset)"
    } else {
        print $"(ansi green)✅ No obvious security issues found(ansi reset)"
    }
}

def check_documentation_issues_code_quality [] {
    print $"\n(ansi blue)🔍 Checking documentation...(ansi reset)"
    let doc_files = (ls docs/**/*.md | get name)
    let readme_files = (ls **/README.md | where name !~ '.git' | get name)
    let all_docs = ($doc_files | append $readme_files)

    let outdated_docs = ($all_docs | each { | file|
        let content = (open $file)
        let outdated_patterns = [
            "setup-wizard",
            "setup-personal",
            "setup-gaming-wizard",
            "setup-gaming-workstation"
        ]

        let has_outdated = ($outdated_patterns | any { | pattern|
            $content | str contains $pattern
        })

        if $has_outdated {
            $file
        }
    } | where ($it != null))

    if ($outdated_docs | length) > 0 {
        print $"\n(ansi yellow)⚠️  Found ($outdated_docs | length) potentially outdated documentation files:(ansi reset)"
        $outdated_docs | each { | f| print $"  ($f)" }
        print $"\n(ansi yellow)💡 Update documentation to reference new unified setup script(ansi reset)"
    } else {
        print $"(ansi green)✅ Documentation appears up to date(ansi reset)"
    }
}

def check_performance [] {
    print $"\n(ansi blue)🔍 Checking for performance issues...(ansi reset)"
    let performance_patterns = [
        "nix build.*--rebuild",
        "nix-collect-garbage.*-d",
        "rm -rf.*nix/store"
    ]
    let performance_issues = ($performance_patterns | each { | pattern|
        let matches = (grep -r -n -i $pattern . --exclude-dir=.git --exclude-dir=coverage-tmp --exclude-dir=tmp out+err> /dev/null | lines | each { | line|
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
        print $"\n(ansi yellow)⚠️  Found ($performance_issues | length) potential performance issues:(ansi reset)"
        $performance_issues | each { | issue|
            print $"  ($issue.file):($issue.line) - Potentially expensive operation"
        }
        print $"\n(ansi yellow)💡 Consider optimizing expensive operations(ansi reset)"
    } else {
        print $"(ansi green)✅ No obvious performance issues found(ansi reset)"
    }
}

# Export functions for use in other scripts
export def analyze_code_quality [] {
    main_code_quality
}

export def check_syntax_issues_code_quality [] {
    let nix_results = (check_nix_syntax)
    let nu_results = (check_syntax_issues_code_quality)

    print $"(ansi blue)Syntax Check Results:(ansi reset)"
    print "===================="

    let nix_errors = ($nix_results | where status == "invalid")
    let nu_errors = ($nu_results | where status == "invalid")

    if ($nix_errors | is-empty) and ($nu_errors | is-empty) {
        print $"(ansi green)✅ All files have valid syntax(ansi reset)"
    } else {
        if not ($nix_errors | is-empty) {
            print $"(ansi red)❌ Nix syntax errors:(ansi reset)"
            for error in $nix_errors {
                print $"  ($error.file): ($error.error)"
            }
        }
        if not ($nu_errors | is-empty) {
            print $"(ansi red)❌ Nushell syntax errors:(ansi reset)"
            for error in $nu_errors {
                print $"  ($error.file): ($error.error)"
            }
        }
    }
}

