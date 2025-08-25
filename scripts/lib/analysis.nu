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
            with_logging "analysis step" {||
                do $analyzer
            }
        } catch { |err|
            warn $"Analysis step failed: ($err.msg)" --context "analysis"
            {}
        }
    } | reduce { |item, acc| $acc | merge $item }
}

# Package size analysis
export def analyze_package_sizes [--output: string = ""] {
    with_logging "package size analysis" --context "analysis" {||
        
        let nix_store_analysis = try {
            let store_size = (du -sh /nix/store 2>/dev/null | split column "\t" | get column1.0 | default "unknown")
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
        
        $analysis
    }
}

# Performance benchmarking
export def benchmark_system_performance [--iterations: int = 5] {
    with_logging "system performance benchmark" --context "benchmark" {||
        
        # CPU benchmark
        let cpu_benchmark = benchmark_cpu_performance $iterations
        
        # Memory benchmark
        let memory_benchmark = benchmark_memory_performance $iterations
        
        # Disk I/O benchmark
        let disk_benchmark = benchmark_disk_performance $iterations
        
        # Nix operations benchmark
        let nix_benchmark = benchmark_nix_operations $iterations
        
        {
            timestamp: (date now),
            iterations: $iterations,
            cpu: $cpu_benchmark,
            memory: $memory_benchmark,
            disk: $disk_benchmark,
            nix: $nix_benchmark
        }
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
    with_logging "code quality analysis" --context "analysis" {||
        
        let file_analysis = analyze_file_metrics $path
        let complexity_analysis = analyze_code_complexity $path
        let duplication_analysis = analyze_code_duplication $path
        
        {
            timestamp: (date now),
            path: $path,
            file_metrics: $file_analysis,
            complexity: $complexity_analysis,
            duplication: $duplication_analysis
        }
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
    with_logging "security posture analysis" --context "security" {||
        
        let file_permissions = analyze_file_permissions
        let dangerous_patterns = scan_for_dangerous_patterns
        let secret_exposure = check_for_exposed_secrets
        
        {
            timestamp: (date now),
            file_permissions: $file_permissions,
            dangerous_patterns: $dangerous_patterns,
            secret_exposure: $secret_exposure,
            overall_score: "analysis not implemented"
        }
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
    print "=== Nix-Mox Analysis Dashboard ==="
    print ""
    
    if "metadata" in $data {
        let meta = ($data | get metadata)
        print $"Generated: ($meta.generated_at)"
        print $"Version: ($meta.version)"
        print ""
    }
    
    if "system" in $data {
        print "📊 System Information:"
        let sys = ($data | get system)
        if "platform" in $sys {
            let platform = ($sys | get platform)
            print $"  Platform: ($platform.normalized) ($platform.arch)"
            print $"  Hostname: ($platform.hostname)"
        }
        print ""
    }
    
    if "packages" in $data {
        print "📦 Package Analysis:"
        let packages = ($data | get packages)
        if "nix_store" in $packages {
            let store = ($packages | get nix_store)
            print $"  Store Size: ($store | get -i total_size | default 'unknown')"
            print $"  Package Count: ($store | get -i package_count | default 'unknown')"
        }
        print ""
    }
    
    if "code_quality" in $data {
        print "🔍 Code Quality:"
        let quality = ($data | get code_quality)
        if "file_metrics" in $quality {
            let metrics = ($quality | get file_metrics)
            print $"  Total Files: ($metrics | get -i total_files | default 'unknown')"
            print $"  Total Lines: ($metrics | get -i total_lines | default 'unknown')"
            print $"  Avg Lines/File: ($metrics | get -i avg_lines_per_file | default 'unknown')"
        }
        print ""
    }
    
    if "security" in $data {
        print "🛡️  Security Analysis:"
        let security = ($data | get security)
        print "  Security posture analysis completed"
        print ""
    }
    
    if "performance" in $data and ($data.performance | get -i note | default "") != "benchmarks not included" {
        print "⚡ Performance Benchmarks:"
        let perf = ($data | get performance)
        print $"  Benchmark completed with ($perf | get -i iterations | default 'unknown') iterations"
        print ""
    }
    
    $data
}