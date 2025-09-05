#!/usr/bin/env nu

# Import unified libraries
use ../../../lib/validators.nu
use ../../../lib/logging.nu *


# Build performance testing module
# Handles Nix evaluation, flake check, and configuration build benchmarks

use ../../lib/test-utils.nu *
use ../../../lib/testing.nu *

export def test_build_performance [] {
    print "(ansi cyan)🔨 Build Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    let results = {}

    # Nix evaluation performance
    print "  Testing Nix evaluation performance..."
    let nix_eval_result = (benchmark_nix_evaluation)
    let results = ($results | upsert nix_eval $nix_eval_result)

    # Flake check performance
    print "  Testing flake check performance..."
    let flake_check_result = (benchmark_flake_check)
    let results = ($results | upsert flake_check $flake_check_result)

    # Configuration build performance
    print "  Testing configuration build performance..."
    let config_build_result = (benchmark_config_build)
    let results = ($results | upsert config_build $config_build_result)

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($results | values | all {| r| $r.success}),
        duration: $duration,
        results: $results
    }
}

def benchmark_nix_evaluation [] {
    let start_time = (date now | into int)
    
    # Test Nix evaluation performance
    let nix_test = (try {
        # Evaluate a simple Nix expression
        let iterations = 10
        let results = (seq 1 $iterations | each {| i|
            try {
                nix eval --extra-experimental-features nix-command --impure --expr 'builtins.currentTime' | str trim
            } catch {
                null
            }
        } | where $it != null)
        
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000
        
        {
            success: (($results | length) == $iterations),
            duration: $duration,
            evaluations: ($results | length),
            expected: $iterations
        }
    } catch {
        {
            success: false,
            error: $env.LAST_ERROR
        }
    })
    
    $nix_test
}

def benchmark_flake_check [] {
    let start_time = (date now | into int)
    
    # Test flake check performance
    let flake_test = (try {
        # Run flake check (dry run)
        let result = (try {
            ^nix flake check --extra-experimental-features nix-command --no-build | complete | get stdout | str trim
            true
        } catch {
            false
        })
        
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000
        
        {
            success: $result,
            duration: $duration
        }
    } catch {
        {
            success: false,
            error: $env.LAST_ERROR
        }
    })
    
    $flake_test
}

def benchmark_config_build [] {
    let start_time = (date now | into int)
    
    # Test configuration build performance
    let config_test = (try {
        # Try to build a simple configuration
        let result = (try {
            ^nix build --extra-experimental-features nix-command --no-link .#default | complete | get stdout | str trim
            true
        } catch {
            false
        })
        
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000
        
        {
            success: $result,
            duration: $duration
        }
    } catch {
        {
            success: false,
            error: $env.LAST_ERROR
        }
    })
    
    $config_test
} 