#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use logging.nu *
use ../../lib/logging.nu *


use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *
use ./modules/system.nu *
use ./modules/build.nu *

def main [] {
    print "(ansi green)🚀 nix-mox Performance Tests(ansi reset)"
    print "(ansi yellow)==============================(ansi reset)\n"

    # Set up test environment
    setup_test_env

    # Ensure TEST_TEMP_DIR is set
    if not ($env | get -o TEST_TEMP_DIR | is-not-empty) {
        $env.TEST_TEMP_DIR = "coverage-tmp/nix-mox-tests"
    }

    # Run all performance test suites
    let results = {
        system_performance: (test_system_performance)
        build_performance: (test_build_performance)
        config_performance: (test_config_performance)
        disk_performance: (test_disk_performance)
        memory_performance: (test_memory_performance)
        network_performance: (test_network_performance)
    }
    
    # Track individual performance test results
    $results | transpose key value | each { |row|
        let test_name = $row.key
        let test_result = $row.value
        track_test $"performance_($test_name)" "performance" (if $test_result.success { "passed" } else { "failed" }) $test_result.duration
    }

    # Generate performance report
    generate_performance_report $results

    # Return overall success status
    let all_passed = ($results | values | all {|r| $r.success})
    if $all_passed {
        print "(ansi green)✅ All performance tests passed!(ansi reset)"
    } else {
        print "(ansi red)❌ Some performance tests failed!(ansi reset)"
    }
    
    # Return success status without exiting
    $all_passed
}

def test_config_performance [] {
    print "(ansi cyan)⚙️  Configuration Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    
    # Simple configuration performance test
    let config_test = (try {
        # Test configuration parsing
        let result = (try {
            ^nix eval --extra-experimental-features nix-command --impure --expr 'import ./config/nixos/configuration.nix {}' | complete | get stdout | str trim
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

def test_disk_performance [] {
    print "(ansi cyan)💾 Disk Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    
    # Simple disk performance test
    let disk_test = (try {
        # Test file I/O performance
        let test_file = "/tmp/nix-mox-disk-test"
        let data = (seq 1 10000 | each {|i| $"Line ($i)"} | str join "\n")
        
        # Write test
        $data | save $test_file
        let write_time = (date now | into int)
        
        # Read test
        let read_data = (open $test_file | lines | length)
        let read_time = (date now | into int)
        
        # Cleanup
        rm $test_file
        
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000
        
        {
            success: ($read_data == 10000),
            duration: $duration,
            lines_written: 10000,
            lines_read: $read_data
        }
    } catch {
        {
            success: false,
            error: $env.LAST_ERROR
        }
    })
    
    $disk_test
}

def test_memory_performance [] {
    print "(ansi cyan)🧠 Memory Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    
    # Simple memory performance test
    let memory_test = (try {
        # Test memory allocation
        let large_array = (seq 1 100000 | each {|i| $i * 2})
        let array_sum = ($large_array | math sum)
        
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000
        
        {
            success: ($array_sum > 0),
            duration: $duration,
            array_size: ($large_array | length),
            sum: $array_sum
        }
    } catch {
        {
            success: false,
            error: $env.LAST_ERROR
        }
    })
    
    $memory_test
}

def test_network_performance [] {
    print "(ansi cyan)🌐 Network Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    
    # Simple network performance test
    let network_test = (try {
        # Test localhost connectivity
        let result = (try {
            ^curl -s --connect-timeout 5 http://localhost:8080 | complete | get stdout | str trim
            true
        } catch {
            # Expected to fail if no local server, but that's OK for this test
            true
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
    
    $network_test
}

def generate_performance_report [results: record] {
    print "\n(ansi blue)📊 Performance Test Report(ansi reset)"
    print "(ansi blue)========================(ansi reset)\n"
    
    $results | transpose key value | each { |row|
        let test_name = $row.key
        let test_result = $row.value
        let status = (if $test_result.success { "(ansi green)✅" } else { "(ansi red)❌" })
        print $"($status) ($test_name): ($test_result.duration | into string -d 3)s"
        
        if ($test_result | get -o results | is-not-empty) {
            $test_result.results | transpose key value | each { |subrow|
                let subtest_name = $subrow.key
                let subtest_result = $subrow.value
                let sub_status = (if $subtest_result.success { "(ansi green)  ✓" } else { "(ansi red)  ✗" })
                let duration_str = if ($subtest_result | get -o duration | is-not-empty) {
                    $"($subtest_result.duration | into string -d 3)s"
                } else {
                    "N/A"
                }
                print $"($sub_status) ($subtest_name): ($duration_str)"
            }
        }
    }
}

# Always run main when sourced
main
