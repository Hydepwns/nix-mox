#!/usr/bin/env nu
# Performance benchmarks module
# Extracted from scripts/test.nu for better organization

use ../../lib/logging.nu *
use ../../lib/testing.nu *
use ../../lib/validators.nu *
use ../../lib/platform.nu *

# ──────────────────────────────────────────────────────────
# PERFORMANCE BENCHMARKS
# ──────────────────────────────────────────────────────────

export def benchmark_logging_performance [] {
    # Benchmark logging system performance
    info "Benchmarking logging performance" --context "benchmark"
    
    let start_time = (date now)
    
    # Perform logging operations
    for i in 0..100 {
        info $"Benchmark log message ($i)" --context "benchmark-test"
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    success $"Logging benchmark completed in ($duration)" --context "benchmark"
    
    {
        success: true,
        benchmark: "logging_performance",
        operations: 100,
        duration: $duration,
        ops_per_second: (100 / ($duration | into int) * 1_000_000_000)
    }
}

export def benchmark_validation_performance [] {
    # Benchmark validation system performance
    info "Benchmarking validation performance" --context "benchmark"
    
    let start_time = (date now)
    
    # Perform validation operations
    for i in 0..50 {
        let _ = (validate_command_available "nix")
        let _ = (validate_file_exists "flake.nix")
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    success $"Validation benchmark completed in ($duration)" --context "benchmark"
    
    {
        success: true,
        benchmark: "validation_performance",
        operations: 100,
        duration: $duration,
        ops_per_second: (100 / ($duration | into int) * 1_000_000_000)
    }
}

export def benchmark_platform_detection [] {
    # Benchmark platform detection performance
    info "Benchmarking platform detection performance" --context "benchmark"
    
    let start_time = (date now)
    
    # Perform platform detection operations
    for i in 0..100 {
        let _ = (get_platform)
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    success $"Platform detection benchmark completed in ($duration)" --context "benchmark"
    
    {
        success: true,
        benchmark: "platform_detection",
        operations: 100,
        duration: $duration,
        ops_per_second: (100 / ($duration | into int) * 1_000_000_000)
    }
}

# ──────────────────────────────────────────────────────────
# BENCHMARK UTILITIES
# ──────────────────────────────────────────────────────────

export def run_benchmark [
    name: string,
    iterations: int,
    operation: closure
] {
    info $"Running benchmark: ($name) with ($iterations) iterations" --context "benchmark"
    
    let start_time = (date now)
    
    for i in 0..$iterations {
        do $operation
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    let result = {
        benchmark: $name,
        iterations: $iterations,
        duration: $duration,
        avg_time_per_op: (($duration | into int) / $iterations),
        ops_per_second: (($iterations * 1_000_000_000) / ($duration | into int))
    }
    
    success $"Benchmark ($name) completed: ($result.ops_per_second) ops/sec" --context "benchmark"
    
    $result
}

export def compare_benchmarks [
    benchmark1: record,
    benchmark2: record
] {
    let speedup = ($benchmark2.ops_per_second / $benchmark1.ops_per_second)
    
    if $speedup > 1.0 {
        success $"($benchmark2.benchmark) is ($speedup)x faster than ($benchmark1.benchmark)" --context "benchmark"
    } else {
        info $"($benchmark1.benchmark) is (1.0 / $speedup)x faster than ($benchmark2.benchmark)" --context "benchmark"
    }
    
    {
        faster: (if $speedup > 1.0 { $benchmark2.benchmark } else { $benchmark1.benchmark }),
        slower: (if $speedup > 1.0 { $benchmark1.benchmark } else { $benchmark2.benchmark }),
        speedup: (if $speedup > 1.0 { $speedup } else { 1.0 / $speedup })
    }
}

# ──────────────────────────────────────────────────────────
# SYSTEM BENCHMARKS
# ──────────────────────────────────────────────────────────

export def benchmark_file_operations [] {
    # Benchmark file system operations
    info "Benchmarking file operations" --context "benchmark"
    
    let temp_file = "/tmp/nix-mox-benchmark-test.txt"
    
    let write_benchmark = (run_benchmark "file_write" 100 {
        "test data" | save $temp_file --force
    })
    
    let read_benchmark = (run_benchmark "file_read" 100 {
        let _ = (open $temp_file)
    })
    
    # Clean up
    try { rm $temp_file } catch { |_| null }
    
    {
        write: $write_benchmark,
        read: $read_benchmark
    }
}

export def benchmark_command_execution [] {
    # Benchmark command execution performance
    info "Benchmarking command execution" --context "benchmark"
    
    let echo_benchmark = (run_benchmark "echo_command" 50 {
        let _ = (echo "benchmark test")
    })
    
    let which_benchmark = (run_benchmark "which_command" 50 {
        let _ = (which nu)
    })
    
    {
        echo: $echo_benchmark,
        which: $which_benchmark
    }
}

export def benchmark_data_processing [] {
    # Benchmark data processing operations
    info "Benchmarking data processing" --context "benchmark"
    
    let test_data = (0..100 | each { |i| { id: $i, name: $"item_($i)" } })
    
    let filter_benchmark = (run_benchmark "data_filter" 50 {
        let _ = ($test_data | where id < 50)
    })
    
    let map_benchmark = (run_benchmark "data_map" 50 {
        let _ = ($test_data | each { |item| $item.name })
    })
    
    let sort_benchmark = (run_benchmark "data_sort" 50 {
        let _ = ($test_data | sort-by id)
    })
    
    {
        filter: $filter_benchmark,
        map: $map_benchmark,
        sort: $sort_benchmark
    }
}

# ──────────────────────────────────────────────────────────
# PERFORMANCE ANALYSIS
# ──────────────────────────────────────────────────────────

export def analyze_performance_results [results: record] {
    info "Analyzing performance results" --context "benchmark"
    
    let benchmarks = ($results | transpose key value | get value)
    let fastest = ($benchmarks | sort-by ops_per_second | last)
    let slowest = ($benchmarks | sort-by ops_per_second | first)
    
    info $"Fastest operation: ($fastest.benchmark) at ($fastest.ops_per_second) ops/sec" --context "benchmark"
    info $"Slowest operation: ($slowest.benchmark) at ($slowest.ops_per_second) ops/sec" --context "benchmark"
    
    let performance_ratio = ($fastest.ops_per_second / $slowest.ops_per_second)
    info $"Performance ratio: ($performance_ratio):1" --context "benchmark"
    
    {
        fastest: $fastest,
        slowest: $slowest,
        performance_ratio: $performance_ratio,
        total_benchmarks: ($benchmarks | length)
    }
}

export def generate_performance_report [results: record] {
    let analysis = (analyze_performance_results $results)
    
    print "=== Performance Benchmark Report ==="
    print ""
    print $"Total benchmarks: ($analysis.total_benchmarks)"
    print $"Fastest: ($analysis.fastest.benchmark) - ($analysis.fastest.ops_per_second) ops/sec"
    print $"Slowest: ($analysis.slowest.benchmark) - ($analysis.slowest.ops_per_second) ops/sec"
    print $"Performance range: ($analysis.performance_ratio):1"
    print ""
    print "Individual Results:"
    
    ($results | transpose name result | each { |row|
        print $"  ($row.name): ($row.result.ops_per_second) ops/sec - ($row.result.duration) total"
    } | ignore)
    
    print ""
    
    $analysis
}