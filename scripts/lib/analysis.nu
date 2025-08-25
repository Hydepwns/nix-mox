#!/usr/bin/env nu
# Consolidated analysis and dashboard library for nix-mox
# Replaces multiple analysis scripts with functional patterns
# Provides composable analysis functions and data collection

use logging.nu *
use platform.nu *
use validators.nu *
use command-wrapper.nu *

# Analysis data pipeline framework
export def analysis_pipeline [...analyzers: closure] {
    $analyzers | par-each { |analyzer|
        try {
            do $analyzer
        } catch { |err|
            warn $"Analysis step failed: ($err.msg)" --context "analysis"
            {}
        }
    } | reduce { |item, acc| $acc | merge $item }
}

# Package size analysis
export def analyze_package_sizes [--output: string = ""] {
    info "Starting package size analysis" --context "analysis"
    let nix_store_analysis = try {
            let store_size = (^du -sh /nix/store 2>/dev/null | split column "\t" | get column1.0 | default "unknown")
            let package_count = try {
                (ls /nix/store | length)
            } catch { 0 }
            
            {
                nix_store: {
                    total_size: $store_size,
                    package_count: $package_count,
                    avg_package_size: (if $package_count > 0 { 
                        "calculation not implemented" 
                    } else { 
                        "no packages" 
                    })
                }
            }
        } catch {
            { nix_store: { error: "failed to analyze Nix store" } }
        }
        
        let generation_analysis = try {
            let generations = (nix-env --list-generations | complete)
            if $generations.exit_code == 0 {
                let gen_count = ($generations.stdout | lines | length)
                {
                    generations: {
                        count: $gen_count,
                        current: (nix-env --list-generations | tail -1)
                    }
                }
            } else {
                { generations: { error: "failed to list generations" } }
            }
        } catch {
            { generations: { error: "generation analysis failed" } }
        }
        
        let analysis = ($nix_store_analysis | merge $generation_analysis)
        
        if not ($output | is-empty) {
            $analysis | to json | save $output
            info $"Package size analysis saved: ($output)" --context "analysis"
        }
        
        success "Package size analysis completed" --context "analysis"
        $analysis
}

# Performance benchmarking
export def benchmark_system_performance [--iterations: int = 5] {
    info "Starting system performance benchmark" --context "benchmark"
    # CPU benchmark
        let cpu_benchmark = benchmark_cpu_performance $iterations
        
        # Memory benchmark
        let memory_benchmark = benchmark_memory_performance $iterations
        
        # Disk I/O benchmark
        let disk_benchmark = benchmark_disk_performance $iterations
        
        # Nix operations benchmark
        let nix_benchmark = benchmark_nix_operations $iterations
        
        success "System performance benchmark completed" --context "benchmark"
        {
            timestamp: (date now),
            iterations: $iterations,
            cpu: $cpu_benchmark,
            memory: $memory_benchmark,
            disk: $disk_benchmark,
            nix: $nix_benchmark
        }
}

def benchmark_cpu_performance [iterations: int] {
    let start_time = (date now)
    
    # Simple CPU stress test
    for _ in 0..$iterations {
        seq 1 1000 | math sum | ignore
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    {
        test: "cpu_math_operations",
        iterations: $iterations,
        total_duration: $duration,
        avg_per_iteration: ($duration / $iterations)
    }
}

def benchmark_memory_performance [iterations: int] {
    let start_memory = (sys mem | get used)
    let start_time = (date now)
    
    # Memory allocation test
    for _ in 0..$iterations {
        let large_list = (seq 1 1000 | collect)
        $large_list | length | ignore
    }
    
    let end_time = (date now)
    let end_memory = (sys mem | get used)
    let duration = ($end_time - $start_time)
    
    {
        test: "memory_allocation",
        iterations: $iterations,
        duration: $duration,
        memory_delta: ($end_memory - $start_memory)
    }
}

def benchmark_disk_performance [iterations: int] {
    let test_file = "tmp/benchmark_test.tmp"
    let start_time = (date now)
    
    try {
        for i in 0..$iterations {
            $"test data ($i)" | save --force $test_file
            open $test_file | ignore
        }
        
        let end_time = (date now)
        let duration = ($end_time - $start_time)
        
        # Cleanup
        if ($test_file | path exists) { rm $test_file }
        
        {
            test: "disk_io_operations",
            iterations: $iterations,
            duration: $duration,
            avg_per_operation: ($duration / $iterations)
        }
    } catch { |err|
        {
            test: "disk_io_operations", 
            error: $err.msg,
            iterations: $iterations
        }
    }
}

def benchmark_nix_operations [iterations: int] {
    let start_time = (date now)
    
    try {
        for _ in 0..$iterations {
            nix store ping | complete | get exit_code | ignore
        }
        
        let end_time = (date now)
        let duration = ($end_time - $start_time)
        
        {
            test: "nix_store_ping",
            iterations: $iterations,
            duration: $duration,
            avg_per_operation: ($duration / $iterations)
        }
    } catch { |err|
        {
            test: "nix_store_ping",
            error: $err.msg,
            iterations: $iterations
        }
    }
}

# Code quality analysis
export def analyze_code_quality [--path: string = "scripts"] {
    info "Starting code quality analysis" --context "analysis"
    let file_analysis = analyze_file_metrics $path
        let complexity_analysis = analyze_code_complexity $path
        let duplication_analysis = analyze_code_duplication $path
        
        success "Code quality analysis completed" --context "analysis"
        {
            timestamp: (date now),
            path: $path,
            file_metrics: $file_analysis,
            complexity: $complexity_analysis,
            duplication: $duplication_analysis
        }
}

def analyze_file_metrics [path: string] {
    try {
        let nu_files = (glob $"($path)/**/*.nu" | default [])
        let sh_files = (glob $"($path)/**/*.sh" | default [])
        let all_files = ($nu_files | append $sh_files)
        
        let total_lines = ($all_files | each { |file|
            try { (open $file | lines | length) } catch { 0 }
        } | math sum)
        
        {
            total_files: ($all_files | length),
            nu_files: ($nu_files | length),
            sh_files: ($sh_files | length),
            total_lines: $total_lines,
            avg_lines_per_file: (if ($all_files | length) > 0 { 
                ($total_lines / ($all_files | length) | math round)
            } else { 0 })
        }
    } catch { |err|
        { error: $"Failed to analyze file metrics: ($err.msg)" }
    }
}

def analyze_code_complexity [path: string] {
    try {
        let nu_files = (glob $"($path)/**/*.nu" | default [])
        
        let function_count = ($nu_files | each { |file|
            try {
                open $file | lines | where ($it =~ "^def ") | length
            } catch { 0 }
        } | math sum)
        
        let export_count = ($nu_files | each { |file|
            try {
                open $file | lines | where ($it =~ "^export def ") | length  
            } catch { 0 }
        } | math sum)
        
        {
            functions: {
                total: $function_count,
                exported: $export_count,
                private: ($function_count - $export_count)
            },
            complexity_score: "not implemented"
        }
    } catch { |err|
        { error: $"Failed to analyze complexity: ($err.msg)" }
    }
}

def analyze_code_duplication [path: string] {
    {
        duplication_analysis: "not implemented",
        note: "Would require advanced text analysis algorithms"
    }
}

# Security analysis
export def analyze_security_posture [] {
    info "Starting security posture analysis" --context "security"
    let file_permissions = analyze_file_permissions
        let dangerous_patterns = scan_for_dangerous_patterns
        let secret_exposure = check_for_exposed_secrets
        
        success "Security posture analysis completed" --context "security"
        {
            timestamp: (date now),
            file_permissions: $file_permissions,
            dangerous_patterns: $dangerous_patterns,
            secret_exposure: $secret_exposure,
            overall_score: "analysis not implemented"
        }
}

def analyze_file_permissions [] {
    try {
        let executable_files = (glob "scripts/**/*.nu" | each { |file|
            let perms = (ls -la $file | get mode | get 0)
            {
                file: $file,
                permissions: $perms,
                executable: ($perms | str contains "x")
            }
        })
        
        {
            total_files: ($executable_files | length),
            executable_count: ($executable_files | where executable == true | length),
            files: $executable_files
        }
    } catch { |err|
        { error: $"Failed to analyze file permissions: ($err.msg)" }
    }
}

def scan_for_dangerous_patterns [] {
    let dangerous_patterns = [
        "rm -rf",
        "sudo rm",
        "chmod 777",
        "eval",
        "password",
        "secret"
    ]
    
    try {
        let findings = ($dangerous_patterns | each { |pattern|
            let matches = (grep -r $pattern scripts | complete)
            {
                pattern: $pattern,
                matches: (if $matches.exit_code == 0 { 
                    ($matches.stdout | lines | length)
                } else { 0 })
            }
        })
        
        {
            patterns_scanned: ($dangerous_patterns | length),
            findings: $findings,
            total_issues: ($findings | get matches | math sum)
        }
    } catch { |err|
        { error: $"Failed to scan for dangerous patterns: ($err.msg)" }
    }
}

def check_for_exposed_secrets [] {
    let secret_patterns = [
        "api_key",
        "API_KEY", 
        "token",
        "TOKEN",
        "password",
        "PASSWORD"
    ]
    
    try {
        let secret_files = ($secret_patterns | each { |pattern|
            let matches = (grep -r $pattern scripts | complete)
            {
                pattern: $pattern,
                found: ($matches.exit_code == 0),
                matches: (if $matches.exit_code == 0 { 
                    ($matches.stdout | lines | length)
                } else { 0 })
            }
        })
        
        {
            patterns_checked: ($secret_patterns | length),
            potential_secrets: ($secret_files | where found == true | length),
            details: $secret_files
        }
    } catch { |err|
        { error: $"Failed to check for exposed secrets: ($err.msg)" }
    }
}

# Generate comprehensive system report
export def generate_system_report [--output: string = "system-report.json", --include-benchmarks = false] {
    info "Generating comprehensive system report..." --context "report"
    
    let system_info = (collect_system_info)
    let package_analysis = (analyze_package_sizes)
    let code_quality = (analyze_code_quality)
    let security_analysis = (analyze_security_posture)
    
    let benchmarks = if $include_benchmarks {
        (benchmark_system_performance)
    } else {
        { note: "benchmarks not included" }
    }
    
    let report = {
        metadata: {
            generated_at: (date now),
            generator: "nix-mox analysis system",
            version: "2.0.0",
            includes_benchmarks: $include_benchmarks
        },
        system: $system_info,
        packages: $package_analysis,
        code_quality: $code_quality,
        security: $security_analysis,
        performance: $benchmarks
    }
    
    $report | to json | save $output
    success $"System report generated: ($output)" --context "report"
    
    $report
}

def collect_system_info [] {
    let platform_info = (get_platform)
    let platform_report = (platform_report)
    
    {
        platform: $platform_info,
        detailed_info: $platform_report,
        nix_info: {
            version: (try { (nix --version | lines | get 0) } catch { "unknown" }),
            store_health: (try { 
                let check = (nix store ping | complete)
                if $check.exit_code == 0 { "healthy" } else { "unhealthy" }
            } catch { "error" })
        }
    }
}

# Dashboard rendering functions  
export def render_analysis_dashboard [data: record, format: string = "terminal"] {
    match $format {
        "json" => ($data | to json),
        "yaml" => ($data | to yaml),
        "terminal" => (format_terminal_dashboard $data),
        _ => ($data | to json)
    }
}

def format_terminal_dashboard [data: record] {
    generate_analysis_report $data
}

# Generate polished analysis report
def generate_analysis_report [data: record] {
    print "nix-mox system analysis"
    print "========================"
    
    if "metadata" in $data {
        let meta = ($data | get metadata)
        let timestamp = ($meta.generated_at | format date '%Y-%m-%d %H:%M UTC')
        print $"generated  : ($timestamp)"
        print ""
    }
    
    # System information
    if "system" in $data {
        print "SYSTEM"
        print "------"
        let sys = ($data | get system)
        
        if "platform" in $sys {
            let platform = ($sys | get platform)
            print $"platform   : ($platform.normalized)/($platform.arch)"
            print $"hostname   : ($platform.hostname)"
        }
        
        if "nix_info" in ($sys | default {}) {
            let nix = ($sys | get nix_info)
            let version = ($nix | get -o version | default 'unknown' | str substring 0..15)
            let health = ($nix | get -o store_health | default 'unknown')
            print $"nix        : ($version)"
            print $"store      : ($health)"
        }
        print ""
    }
    
    # Package analysis
    if "packages" in $data {
        print "PACKAGES"
        print "--------"
        let packages = ($data | get packages)
        
        if "nix_store" in $packages {
            let store = ($packages | get nix_store)
            let size = ($store | get -o total_size | default 'unknown')
            let count = ($store | get -o package_count | default 0)
            print $"store size : ($size)"
            print $"packages   : ($count)"
        }
        
        if "generations" in $packages {
            let generations = ($packages | get generations)
            if "count" in $generations {
                let gen_count = ($generations | get count)
                let status = if $gen_count > 10 { " (cleanup recommended)" } else { "" }
                print $"generations: ($gen_count)($status)"
            }
        }
        print ""
    }
    
    # Code quality  
    if "code_quality" in $data {
        print "CODE QUALITY"
        print "------------"
        let quality = ($data | get code_quality)
        
        if "file_metrics" in $quality {
            let metrics = ($quality | get file_metrics)
            let files = ($metrics | get -o total_files | default 0)
            let lines = ($metrics | get -o total_lines | default 0)  
            let avg = ($metrics | get -o avg_lines_per_file | default 0)
            
            print $"files      : ($files)"
            print $"lines      : ($lines)"
            print $"avg/file   : ($avg)" + (if $avg > 200 { " (large files detected)" } else { "" })
        }
        
        if "complexity" in $quality {
            let complexity = ($quality | get complexity)
            if "functions" in $complexity {
                let functions = ($complexity | get functions)
                let total = ($functions | get -o total | default 0)
                let exported = ($functions | get -o exported | default 0)
                
                if $total > 0 {
                    let ratio = ($exported * 100 / $total | math round)
                    let surface_note = if $ratio > 50 { " (high API surface)" } else { "" }
                    print $"functions  : ($total) total, ($exported) public (($ratio)%)($surface_note)"
                }
            }
        }
        print ""
    }
    
    # Security assessment
    if "security" in $data {
        print "SECURITY"
        print "--------"
        let security = ($data | get security)
        mut has_issues = false
        
        if "dangerous_patterns" in $security {
            let patterns = ($security | get dangerous_patterns)
            let count = ($patterns | get -o total_issues | default 0)
            if $count > 0 {
                print $"dangerous  : ($count) patterns found"
                $has_issues = true
            }
        }
        
        if "secret_exposure" in $security {
            let secrets = ($security | get secret_exposure)
            let count = ($secrets | get -o potential_secrets | default 0)
            if $count > 0 {
                print $"secrets    : ($count) potential exposures"
                $has_issues = true
            }
        }
        
        if "file_permissions" in $security {
            let perms = ($security | get file_permissions)
            if "executable_count" in $perms {
                let exec_count = ($perms | get executable_count)
                let total_count = ($perms | get -o total_files | default 0)
                if $total_count > 0 {
                    let ratio = ($exec_count * 100 / $total_count | math round)
                    print $"executable : ($exec_count)/($total_count) files (($ratio)%)"
                }
            }
        }
        
        if not $has_issues {
            print "status     : no issues detected"
        }
        print ""
    }
    
    # Performance (if available)
    if "performance" in $data and ($data.performance | get -o note | default "") != "benchmarks not included" {
        print "PERFORMANCE"
        print "-----------"
        let perf = ($data | get performance)
        let iterations = ($perf | get -o iterations | default 0)
        print $"benchmark  : ($iterations) iterations completed"
        print ""
    }
    
    # Action items
    let actions = (generate_action_items $data)
    if ($actions | length) > 0 {
        print "ACTIONS REQUIRED"
        print "----------------"
        for action in $actions {
            print $"• ($action)"
        }
    } else {
        print "STATUS: No actions required"
    }
    print ""
    
    $data
}

# Generate ASCII usage bar
def generate_usage_bar [current: int, max: int, width: int] {
    let ratio = ($current / $max)
    let filled = ($ratio * $width | math floor)
    let empty = ($width - $filled)
    
    # Build bar using string repetition
    let filled_chars = (0..$filled | each { "█" } | str join "")
    let empty_chars = (0..$empty | each { "░" } | str join "")
    $"[($filled_chars)($empty_chars)]"
}

# Generate concise action items
def generate_action_items [data: record] {
    mut actions = []
    
    if "packages" in $data {
        let gen_count = ($data | get packages | get -o generations.count | default 0)
        if $gen_count > 10 {
            $actions = ($actions | append "clean old generations")
        }
    }
    
    if "security" in $data {
        let security = ($data | get security)
        let issues = ($security | get -o dangerous_patterns.total_issues | default 0)
        let secrets = ($security | get -o secret_exposure.potential_secrets | default 0)
        
        if $issues > 0 { $actions = ($actions | append "review dangerous patterns") }
        if $secrets > 0 { $actions = ($actions | append "secure exposed credentials") }
    }
    
    if "code_quality" in $data {
        let avg_lines = ($data | get code_quality | get -o file_metrics.avg_lines_per_file | default 0)
        if $avg_lines > 200 {
            $actions = ($actions | append "refactor large files")
        }
    }
    
    $actions
}