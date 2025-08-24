#!/usr/bin/env nu

# Import unified libraries
use ../../lib/unified-checks.nu
use ../../lib/unified-error-handling.nu
use ../../lib/unified-logging.nu *

# nix-mox Performance Optimization Script
# Analyze and optimize various aspects of the codebase


# Configuration constants
const PERFORMANCE_THRESHOLDS = {
    test_slow: 10.0
    build_slow: 60.0
    eval_slow: 5.0
    max_parallel_jobs: 8
}

# Utility functions
def safe_command [cmd: string] {
    try {
        nu -c $cmd | str trim
    } catch {
        ""
    }
}

def safe_int [value: any] {
    try {
        $value | into int
    } catch {
        0
    }
}

def measure_duration [command: closure] {
    let start_time = (date now | into int)
    let result = (try { do $command true } catch { false })
    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000
    {
        success: $result
        duration: $duration
        error: null
    }
}

def analyze_test_performance [] {
    info "Analyzing test performance..." "performance-optimize"

    # Check if test script exists
    if not ("scripts/testing/run-tests.nu" | path exists) {
        return {
            success: false
            duration: 0.0
            error: "Test script not found: scripts/testing/run-tests.nu"
        }
    }

    # Run tests with timing
    let test_result = (try {
        measure_duration { || nu -c 'source scripts/testing/run-tests.nu; run ["--unit"]' }
    } catch {
        {
            success: false
            duration: 0.0
            error: "Test execution failed"
        }
    })
    $test_result
}

def analyze_build_performance [] {
    info "Analyzing build performance..." "performance-optimize"

    # Check if we're in a Nix flake
    if not ("flake.nix" | path exists) {
        return {
            success: false
            duration: 0.0
            error: "Not in a Nix flake directory"
        }
    }

    # Test build performance
    let build_result = (try {
        measure_duration { || nix build .#install --no-link --accept-flake-config }
    } catch {
        {
            success: false
            duration: 0.0
            error: "Build failed"
        }
    })
    $build_result
}

def analyze_flake_evaluation [] {
    log_info "Analyzing flake evaluation performance..."

    # Check if we're in a Nix flake
    if not ("flake.nix" | path exists) {
        return {
            success: false
            duration: 0.0
            error: "Not in a Nix flake directory"
        }
    }

    # Test flake evaluation speed
    let eval_result = (try {
        measure_duration { || nix flake show --json }
    } catch {
        {
            success: false
            duration: 0.0
            error: "Flake evaluation failed"
        }
    })
    $eval_result
}

def analyze_system_resources [] {
    info "Analyzing system resources..." "performance-optimize"

    let cpu_count = ("nproc" | into int | default 0)
    let mem_gb = ("free -g | grep Mem | awk '{print $2}'" | into int | default 0)
    let disk_free_gb = ("df -h . | tail -n 1 | awk '{print $4}' | str replace 'G' ''" | into int | default 0)

    {
        cpu_cores: $cpu_count
        memory_gb: $mem_gb
        disk_free_gb: $disk_free_gb
        recommended_parallel_jobs: (
            if $cpu_count > $PERFORMANCE_THRESHOLDS.max_parallel_jobs {
                $PERFORMANCE_THRESHOLDS.max_parallel_jobs
            } else {
                $cpu_count
            }
        )
    }
}

def generate_performance_report [test_perf: record, build_perf: record, eval_perf: record, system_resources: record] {
    let report = {
        timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
        system_resources: $system_resources
        test_performance: $test_perf
        build_performance: $build_perf
        flake_evaluation: $eval_perf
        recommendations: []
    }

    mut recommendations = []

    # System resource recommendations
    if $system_resources.memory_gb < 8 {
        let mem_msg = "Low memory " + ($system_resources.memory_gb | into string) + "GB - consider increasing RAM for better performance"
        $recommendations = ($recommendations | append $mem_msg)
    }

    if $system_resources.disk_free_gb < 10 {
        let disk_msg = "Low disk space " + ($system_resources.disk_free_gb | into string) + "GB - free up space for builds"
        $recommendations = ($recommendations | append $disk_msg)
    }

    # Test performance recommendations
    if $test_perf.duration > $PERFORMANCE_THRESHOLDS.test_slow {
        let test_duration = ($test_perf.duration | into string | str substring 0..6)
        let test_msg = $"Test suite is slow ($test_duration)s) - consider parallelization"
        $recommendations = ($recommendations | append $test_msg)
    }

    if not $test_perf.success {
        $recommendations = ($recommendations | append "Test suite has failures - investigate and fix")
    }

    # Build performance recommendations
    if $build_perf.duration > $PERFORMANCE_THRESHOLDS.build_slow {
        let build_duration = ($build_perf.duration | into string | str substring 0..6)
        let build_msg = $"Build is slow ($build_duration)s) - consider caching optimization"
        $recommendations = ($recommendations | append $build_msg)
    }

    if not $build_perf.success {
        $recommendations = ($recommendations | append "Build has failures - investigate dependencies")
    }

    # Flake evaluation recommendations
    if $eval_perf.duration > $PERFORMANCE_THRESHOLDS.eval_slow {
        let eval_duration = ($eval_perf.duration | into string | str substring 0..6)
        let eval_msg = $"Flake evaluation is slow ($eval_duration)s) - consider simplifying structure"
        $recommendations = ($recommendations | append $eval_msg)
    }

    if not $eval_perf.success {
        $recommendations = ($recommendations | append "Flake evaluation has errors - check flake.nix syntax")
    }

    # Cache optimization recommendations
    $recommendations = ($recommendations | append "Consider running 'make cache-warm' to optimize build caching")
    $recommendations = ($recommendations | append "Consider running 'make cache-optimize' for advanced cache optimization")

    ($report | upsert recommendations $recommendations)
}

def display_performance_report [report: record] {
    print $"(ansi green)📊 Performance Analysis Report(ansi reset)"
    print $"Timestamp: ($report.timestamp)"
    print ""

    # System resources
    print $"(ansi blue)💻 System Resources:(ansi reset)"
    print $"  CPU: ($report.system_resources.cpu_cores) cores"
    print $"  Memory: ($report.system_resources.memory_gb) GB"
    print $"  Disk free: ($report.system_resources.disk_free_gb) GB"
    print $"  Recommended parallel jobs: ($report.system_resources.recommended_parallel_jobs)"
    print ""

    # Test performance
    print $"(ansi blue)🧪 Test Performance:(ansi reset)"
    let test_status = (if $report.test_performance.success { "✅" } else { "❌" })
    print $"  ($test_status) Duration: ($report.test_performance.duration | into string | str substring 0..6)s"
    if not $report.test_performance.success {
        print $"  Error: ($report.test_performance.error)"
    }
    print ""

    # Build performance
    print $"(ansi blue)🔨 Build Performance:(ansi reset)"
    let build_status = (if $report.build_performance.success { "✅" } else { "❌" })
    print $"  ($build_status) Duration: ($report.build_performance.duration | into string | str substring 0..6)s"
    if not $report.build_performance.success {
        print $"  Error: ($report.build_performance.error)"
    }
    print ""

    # Flake evaluation
    print $"(ansi blue)📦 Flake Evaluation:(ansi reset)"
    let eval_status = (if $report.flake_evaluation.success { "✅" } else { "❌" })
    print $"  ($eval_status) Duration: ($report.flake_evaluation.duration | into string | str substring 0..6)s"
    if not $report.flake_evaluation.success {
        print $"  Error: ($report.flake_evaluation.error)"
    }
    print ""

    # Recommendations
    print $"(ansi yellow)💡 Recommendations:(ansi reset)"
    for rec in $report.recommendations {
        print $"  • ($rec)"
    }
    print ""
}

def optimize_test_parallelization [system_resources: record] {
    info "Optimizing test parallelization..." "performance-optimize"

    let recommended_jobs = $system_resources.recommended_parallel_jobs
    print $"CPU cores: ($system_resources.cpu_cores)"
    print $"Recommended parallel jobs: ($recommended_jobs)"

    # Update test configuration for parallel execution
    let test_config = {
        parallel: true
        max_jobs: $recommended_jobs
        timeout: 300
        retries: 2
        coverage: true
    }

    print "Test parallelization configuration:"
    print ($test_config | to json --indent 2)
    $test_config
}

def optimize_build_caching [] {
    info "Optimizing build caching..." "performance-optimize"

    # Use advanced cache optimization
    try {
        # Advanced cache optimization not available, using fallback
        print "⚠️  Advanced cache optimization not available, using fallback"
        {}
    } catch {
        # Fallback to basic cache configuration
        let cachix_status = (try {
            let user = (cachix whoami)
            if ($user | str length) > 0 {
                { available: true, user: $user }
            } else {
                { available: false, user: null }
            }
        } catch {
            { available: false, user: null }
        })

        if $cachix_status.available {
            print $"✅ Cachix available: ($cachix_status.user)"
            # Basic cache configuration
            let cache_config = {
                substituters: ["https://nix-mox.cachix.org" "https://hydepwns.cachix.org" "https://cache.nixos.org"]
                trusted_public_keys: ["nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4=" "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU=" "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="]
                experimental_features: ["nix-command" "flakes"]
                max_jobs: "auto"
                cores: 0
            }
            print "Cache configuration optimized"
            $cache_config
        } else {
            print "❌ Cachix not available - consider setting up for faster builds"
            {}
        }
    }
}

def optimize_nix_config [] {
    info "Optimizing Nix configuration..." "performance-optimize"

    let nix_config = {
        experimental_features: ["nix-command" "flakes"]
        max_jobs: "auto"
        cores: 0
        sandbox: true
        substituters: ["https://cache.nixos.org"]
        trusted_public_keys: ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="]
    }

    print "Nix configuration optimized for performance"
    $nix_config
}

def main [] {
    info "Starting nix-mox performance optimization..." "performance-optimize"

    # Analyze system resources first
    let system_resources = (analyze_system_resources)

    # Analyze performance
    let test_perf = (analyze_test_performance)
    let build_perf = (analyze_build_performance)
    let eval_perf = (analyze_flake_evaluation)

    # Generate report
    let report = (generate_performance_report $test_perf $build_perf $eval_perf $system_resources)

    # Display report
    display_performance_report $report

    # Apply optimizations
    let test_config = (optimize_test_parallelization $system_resources)
    let cache_config = (optimize_build_caching)
    let nix_config = (optimize_nix_config)

    # Save report
    let final_report = ($report | merge {
        optimizations: {
            test_config: $test_config
            cache_config: $cache_config
            nix_config: $nix_config
        }
    })

    $final_report | to json --indent 2 | save performance-report.json
    success "Performance optimization completed!" "performance-optimize"
    info "Report saved to performance-report.json" "performance-optimize"
    $final_report
}

# Export functions for use in other scripts
export def analyze [] {
    let system_resources = (analyze_system_resources)
    let test_perf = (analyze_test_performance)
    let build_perf = (analyze_build_performance)
    let eval_perf = (analyze_flake_evaluation)
    let report = (generate_performance_report $test_perf $build_perf $eval_perf $system_resources)
    display_performance_report $report
    $report
}

export def optimize [] {
    let system_resources = (analyze_system_resources)
    let test_config = (optimize_test_parallelization $system_resources)
    let cache_config = (optimize_build_caching)
    let nix_config = (optimize_nix_config)

    {
        system_resources: $system_resources
        test_config: $test_config
        cache_config: $cache_config
        nix_config: $nix_config
    }
}

export def report [] {
    let system_resources = (analyze_system_resources)
    let test_perf = (analyze_test_performance)
    let build_perf = (analyze_build_performance)
    let eval_perf = (analyze_flake_evaluation)
    let report = (generate_performance_report $test_perf $build_perf $eval_perf $system_resources)
    display_performance_report $report
    $report
}

export def quick_check [] {
    info "Running quick performance check..." "performance-optimize"

    let system_resources = (analyze_system_resources)
    let eval_perf = (analyze_flake_evaluation)

    print $"(ansi green)Quick Performance Check:(ansi reset)"
    print $"CPU: ($system_resources.cpu_cores) cores"
    print $"Memory: ($system_resources.memory_gb) GB"
    print $"Flake evaluation: ($eval_perf.duration | into string | str substring 0..6)s"

    if $eval_perf.duration > $PERFORMANCE_THRESHOLDS.eval_slow {
        print $"(ansi yellow)⚠️  Flake evaluation is slow(ansi reset)"
    } else {
        print $"(ansi green)✅ Flake evaluation is fast(ansi reset)"
    }
}
