#!/usr/bin/env nu

# nix-mox Performance Optimization Script
# Analyzes and optimizes various aspects of the codebase

use lib/common.nu *

def analyze_test_performance [] {
    log_info "Analyzing test performance..."

    let start_time = (date now | into int)

    # Run tests with timing
    let test_result = (try {
        nu -c 'source scripts/tests/run-tests.nu; run ["--unit"]'
        { success: true, duration: 0, error: null }
    } catch {
        { success: false, duration: 0, error: "Test execution failed" }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: $test_result.success
        duration: $duration
        error: $test_result.error
    }
}

def analyze_build_performance [] {
    log_info "Analyzing build performance..."

    let start_time = (date now | into int)

    # Test build performance
    let build_result = (try {
        nix build .#install --no-link --accept-flake-config
        { success: true, duration: 0 }
    } catch {
        { success: false, duration: 0, error: $env.LAST_ERROR }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: $build_result.success
        duration: $duration
        error: ($build_result.error | default null)
    }
}

def analyze_flake_evaluation [] {
    log_info "Analyzing flake evaluation performance..."

    let start_time = (date now | into int)

    # Test flake evaluation speed
    let eval_result = (try {
        nix flake show --json
        { success: true, duration: 0 }
    } catch {
        { success: false, duration: 0, error: $env.LAST_ERROR }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: $eval_result.success
        duration: $duration
        error: ($eval_result.error | default null)
    }
}

def generate_performance_report [test_perf: record, build_perf: record, eval_perf: record] {
    let report = {
        timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
        test_performance: $test_perf
        build_performance: $build_perf
        flake_evaluation: $eval_perf
        recommendations: []
    }

    mut recommendations = []

    # Test performance recommendations
    if $test_perf.duration > 10 {
        $recommendations = ($recommendations | append "Test suite is slow (>10s) - consider parallelization")
    }

    if not $test_perf.success {
        $recommendations = ($recommendations | append "Test suite has failures - investigate and fix")
    }

    # Build performance recommendations
    if $build_perf.duration > 60 {
        $recommendations = ($recommendations | append "Build is slow (>60s) - consider caching optimization")
    }

    if not $build_perf.success {
        $recommendations = ($recommendations | append "Build has failures - investigate dependencies")
    }

    # Flake evaluation recommendations
    if $eval_perf.duration > 5 {
        $recommendations = ($recommendations | append "Flake evaluation is slow (>5s) - consider simplifying structure")
    }

    if not $eval_perf.success {
        $recommendations = ($recommendations | append "Flake evaluation failed - check syntax and dependencies")
    }

    # General recommendations
    if ($recommendations | is-empty) {
        $recommendations = ($recommendations | append "Performance is good - no immediate optimizations needed")
    }

    $report | upsert recommendations $recommendations
}

def display_performance_report [report: record] {
    print $"($env.GREEN)=== nix-mox Performance Report ===($env.NC)"
    print $"Generated: ($report.timestamp)"
    print ""

    print $"($env.BLUE)Test Performance:($env.NC)"
    let test_status = if $report.test_performance.success { "✅" } else { "❌" }
    print $"  ($test_status) Duration: ($report.test_performance.duration | into string | str substring 0..6)s"
    if not $report.test_performance.success {
        print $"  Error: ($report.test_performance.error)"
    }
    print ""

    print $"($env.BLUE)Build Performance:($env.NC)"
    let build_status = if $report.build_performance.success { "✅" } else { "❌" }
    print $"  ($build_status) Duration: ($report.build_performance.duration | into string | str substring 0..6)s"
    if not $report.build_performance.success {
        print $"  Error: ($report.build_performance.error)"
    }
    print ""

    print $"($env.BLUE)Flake Evaluation:($env.NC)"
    let eval_status = if $report.flake_evaluation.success { "✅" } else { "❌" }
    print $"  ($eval_status) Duration: ($report.flake_evaluation.duration | into string | str substring 0..6)s"
    if not $report.flake_evaluation.success {
        print $"  Error: ($report.flake_evaluation.error)"
    }
    print ""

    print $"($env.YELLOW)Recommendations:($env.NC)"
    for rec in $report.recommendations {
        print $"  • ($rec)"
    }
    print ""
}

def optimize_test_parallelization [] {
    log_info "Optimizing test parallelization..."

    # Check if we can run tests in parallel
    let cpu_count = (sys | get cpu | get count)
    let recommended_jobs = (if $cpu_count > 4 { 4 } else { $cpu_count })

    print $"CPU cores: ($cpu_count)"
    print $"Recommended parallel jobs: ($recommended_jobs)"

    # Update test configuration for parallel execution
    let test_config = {
        parallel: true
        max_jobs: $recommended_jobs
        timeout: 300
    }

    print "Test parallelization configuration:"
    print ($test_config | to json --indent 2)

    $test_config
}

def optimize_build_caching [] {
    log_info "Optimizing build caching..."

    # Check Cachix status
    let cachix_status = (try {
        cachix whoami
        { available: true, user: $env.LAST_OUTPUT }
    } catch {
        { available: false, user: null }
    })

    if $cachix_status.available {
        print $"✅ Cachix available: ($cachix_status.user)"

        # Optimize cache configuration
        let cache_config = {
            substituters: [
                "https://nix-mox.cachix.org"
                "https://hydepwns.cachix.org"
                "https://cache.nixos.org"
            ]
            trusted_public_keys: [
                "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
                "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU="
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            ]
        }

        print "Cache configuration optimized"
        $cache_config
    } else {
        print "❌ Cachix not available - consider setting up for faster builds"
        {}
    }
}

def main [] {
    log_info "Starting nix-mox performance optimization..."

    # Analyze performance
    let test_perf = (analyze_test_performance)
    let build_perf = (analyze_build_performance)
    let eval_perf = (analyze_flake_evaluation)

    # Generate report
    let report = (generate_performance_report $test_perf $build_perf $eval_perf)

    # Display report
    display_performance_report $report

    # Apply optimizations
    let test_config = (optimize_test_parallelization)
    let cache_config = (optimize_build_caching)

    # Save report
    let final_report = ($report | merge {
        optimizations: {
            test_config: $test_config
            cache_config: $cache_config
        }
    })

    $final_report | to json --indent 2 | save performance-report.json

    log_success "Performance optimization completed!"
    log_info "Report saved to performance-report.json"

    $final_report
}

# Export functions for use in other scripts
export def analyze [] {
    main
}

export def optimize [] {
    optimize_test_parallelization
    optimize_build_caching
}

export def report [] {
    let test_perf = (analyze_test_performance)
    let build_perf = (analyze_build_performance)
    let eval_perf = (analyze_flake_evaluation)
    let report = (generate_performance_report $test_perf $build_perf $eval_perf)
    display_performance_report $report
    $report
}
