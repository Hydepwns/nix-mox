#!/usr/bin/env nu

use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *

def main [] {
    print "(ansi green)🚀 nix-mox Performance Tests(ansi reset)"
    print "(ansi yellow)==============================(ansi reset)\n"

    # Set up test environment
    setup_test_env

    # Ensure TEST_TEMP_DIR is set
    if not ($env | get -i TEST_TEMP_DIR | is-not-empty) {
        $env.TEST_TEMP_DIR = "/tmp/nix-mox-tests"
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

    # Generate performance report
    generate_performance_report $results

    # Return overall success status
    let all_passed = ($results | values | all {|r| $r.success})
    if $all_passed {
        print "(ansi green)✅ All performance tests passed!(ansi reset)"
        exit 0
    } else {
        print "(ansi red)❌ Some performance tests failed!(ansi reset)"
        exit 1
    }
}

def test_system_performance [] {
    print "(ansi cyan)🖥️  System Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    let results = {}

    # CPU performance test
    print "  Testing CPU performance..."
    let cpu_result = (benchmark_cpu)
    let results = ($results | upsert cpu $cpu_result)

    # System load test
    print "  Testing system load..."
    let load_result = (benchmark_system_load)
    let results = ($results | upsert load $load_result)

    # Process creation test
    print "  Testing process creation..."
    let process_result = (benchmark_process_creation)
    let results = ($results | upsert process $process_result)

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($results | values | all {|r| $r.success}),
        duration: $duration,
        results: $results
    }
}

def test_build_performance [] {
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
        success: ($results | values | all {|r| $r.success}),
        duration: $duration,
        results: $results
    }
}

def test_config_performance [] {
    print "(ansi cyan)⚙️  Configuration Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    let results = {}

    # Configuration parsing performance
    print "  Testing configuration parsing..."
    let parse_result = (benchmark_config_parsing)
    let results = ($results | upsert parsing $parse_result)

    # Configuration validation performance
    print "  Testing configuration validation..."
    let validation_result = (benchmark_config_validation)
    let results = ($results | upsert validation $validation_result)

    # Template processing performance
    print "  Testing template processing..."
    let template_result = (benchmark_template_processing)
    let results = ($results | upsert template $template_result)

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($results | values | all {|r| $r.success}),
        duration: $duration,
        results: $results
    }
}

def test_disk_performance [] {
    print "(ansi cyan)💾 Disk Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    let results = {}

    # Disk read performance
    print "  Testing disk read performance..."
    let read_result = (benchmark_disk_read)
    let results = ($results | upsert read $read_result)

    # Disk write performance
    print "  Testing disk write performance..."
    let write_result = (benchmark_disk_write)
    let results = ($results | upsert write $write_result)

    # File system performance
    print "  Testing file system performance..."
    let fs_result = (benchmark_filesystem)
    let results = ($results | upsert filesystem $fs_result)

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($results | values | all {|r| $r.success}),
        duration: $duration,
        results: $results
    }
}

def test_memory_performance [] {
    print "(ansi cyan)🧠 Memory Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    let results = {}

    # Memory allocation performance
    print "  Testing memory allocation..."
    let alloc_result = (benchmark_memory_allocation)
    let results = ($results | upsert allocation $alloc_result)

    # Memory access performance
    print "  Testing memory access..."
    let access_result = (benchmark_memory_access)
    let results = ($results | upsert access $access_result)

    # Swap performance
    print "  Testing swap performance..."
    let swap_result = (benchmark_swap_performance)
    let results = ($results | upsert swap $swap_result)

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($results | values | all {|r| $r.success}),
        duration: $duration,
        results: $results
    }
}

def test_network_performance [] {
    print "(ansi cyan)🌐 Network Performance Tests...(ansi reset)"
    let start_time = (date now | into int)
    let results = {}

    # Network connectivity test
    print "  Testing network connectivity..."
    let connectivity_result = (benchmark_network_connectivity)
    let results = ($results | upsert connectivity $connectivity_result)

    # DNS resolution performance
    print "  Testing DNS resolution..."
    let dns_result = (benchmark_dns_resolution)
    let results = ($results | upsert dns $dns_result)

    # Download speed test
    print "  Testing download speed..."
    let download_result = (benchmark_download_speed)
    let results = ($results | upsert download $download_result)

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($results | values | all {|r| $r.success}),
        duration: $duration,
        results: $results
    }
}

# --- Benchmark Functions ---

def benchmark_cpu [] {
    let start_time = (date now | into int)

    # Simple CPU benchmark using mathematical operations
    let iterations = 1000000
    let result = (seq 1 $iterations | each {|i| $i * 2} | math sum)

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($result > 0),
        duration: $duration,
        score: ($iterations / $duration),
        result: $result
    }
}

def benchmark_system_load [] {
    let start_time = (date now | into int)

    # Get system load average using uptime
    let uptime_output = (uptime | str trim)
    let cpu_count = (sys cpu | length)

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: true,
        duration: $duration,
        load_info: $uptime_output,
        cpu_count: $cpu_count
    }
}

def benchmark_process_creation [] {
    let start_time = (date now | into int)

    # Test process creation speed
    let iterations = 100
    let results = (seq 1 $iterations | each {|i|
        let proc_start = (date now | into int)
        let result = (echo "test" | head -n 1)
        let proc_end = (date now | into int)
        (($proc_end - $proc_start) | into float) / 1000000000
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000
    let avg_proc_time = ($results | math avg)

    {
        success: true,
        duration: $duration,
        avg_process_time: $avg_proc_time,
        total_processes: $iterations
    }
}

def benchmark_nix_evaluation [] {
    let start_time = (date now | into int)

    # Test Nix evaluation performance
    let result = (try {
        nix eval --raw .#checks.x86_64-linux | ignore
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
}

def benchmark_flake_check [] {
    let start_time = (date now | into int)

    # Test flake check performance
    let result = (try {
        nix flake check --no-build | ignore
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
}

def benchmark_config_build [] {
    let start_time = (date now | into int)

    # Test configuration build performance (dry run)
    let result = (try {
        nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run | ignore
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
}

def benchmark_config_parsing [] {
    let start_time = (date now | into int)

    # Test configuration file parsing performance
    let config_files = (ls config/**/*.nix | get name)
    let parse_times = ($config_files | each {|file|
        let parse_start = (date now | into int)
        let result = (try {
            nix-instantiate --parse $file | ignore
            true
        } catch {
            false
        })
        let parse_end = (date now | into int)
        {
            file: $file,
            success: $result,
            duration: ((($parse_end - $parse_start) | into float) / 1000000000)
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($parse_times | all {|p| $p.success}),
        duration: $duration,
        files_parsed: ($parse_times | length),
        avg_parse_time: ($parse_times | get duration | math avg)
    }
}

def benchmark_config_validation [] {
    let start_time = (date now | into int)

    # Test configuration validation performance
    let result = (try {
        nix-instantiate --dry-run flake.nix | ignore
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
}

def benchmark_template_processing [] {
    let start_time = (date now | into int)

    # Test template processing performance
    let templates = (ls config/templates/*.nix | get name)
    let process_times = ($templates | each {|template|
        let process_start = (date now | into int)
        let result = (try {
            cat $template | head -n 10 | ignore
            true
        } catch {
            false
        })
        let process_end = (date now | into int)
        {
            template: $template,
            success: $result,
            duration: ((($process_end - $process_start) | into float) / 1000000000)
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    {
        success: ($process_times | all {|p| $p.success}),
        duration: $duration,
        templates_processed: ($process_times | length),
        avg_process_time: ($process_times | get duration | math avg)
    }
}

def benchmark_disk_read [] {
    let start_time = (date now | into int)

    # Test disk read performance using dd
    let test_file = $env.TEST_TEMP_DIR + "/disk_test"
    let result = (try {
        # Create test file
        dd if=/dev/zero of=$test_file bs=1M count=100 | ignore

        # Test read performance
        let read_start = (date now | into int)
        dd if=$test_file of=/dev/null bs=1M | ignore
        let read_end = (date now | into int)
        let read_duration = (($read_end - $read_start) | into float) / 1000000000

        # Cleanup
        rm -f $test_file

        {
            success: true,
            duration: $read_duration,
            speed: "100MB read completed"
        }
    } catch {
        {
            success: false,
            duration: 0,
            speed: "Failed"
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert total_duration $duration)
}

def benchmark_disk_write [] {
    let start_time = (date now | into int)

    # Test disk write performance
    let test_file = $env.TEST_TEMP_DIR + "/write_test"
    let result = (try {
        let write_start = (date now | into int)
        dd if=/dev/zero of=$test_file bs=1M count=50 | ignore
        let write_end = (date now | into int)
        let write_duration = (($write_end - $write_start) | into float) / 1000000000

        # Cleanup
        rm -f $test_file

        {
            success: true,
            duration: $write_duration,
            speed: "50MB write completed"
        }
    } catch {
        {
            success: false,
            duration: 0,
            speed: "Failed"
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert total_duration $duration)
}

def benchmark_filesystem [] {
    let start_time = (date now | into int)

    # Test filesystem operations
    let test_dir = $env.TEST_TEMP_DIR + "/fs_test"
    let result = (try {
        mkdir $test_dir

        # Test file creation
        let create_start = (date now | into int)
        seq 1 1000 | each {|i| echo $i > ($test_dir + "/file_" + $i)}
        let create_end = (date now | into int)
        let create_duration = (($create_end - $create_start) | into float) / 1000000000

        # Test file listing
        let list_start = (date now | into int)
        ls $test_dir | length
        let list_end = (date now | into int)
        let list_duration = (($list_end - $list_start) | into float) / 1000000000

        # Cleanup
        rm -rf $test_dir

        {
            success: true,
            create_duration: $create_duration,
            list_duration: $list_duration,
            files_created: 1000
        }
    } catch {
        {
            success: false,
            create_duration: 0,
            list_duration: 0,
            files_created: 0
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert total_duration $duration)
}

def benchmark_memory_allocation [] {
    let start_time = (date now | into int)

    # Test memory allocation performance
    let result = (try {
        # Simple memory allocation test using large arrays
        let alloc_start = (date now | into int)
        let large_array = (seq 1 100000)
        let alloc_end = (date now | into int)
        let alloc_duration = (($alloc_end - $alloc_start) | into float) / 1000000000

        {
            success: true,
            duration: $alloc_duration,
            elements: ($large_array | length)
        }
    } catch {
        {
            success: false,
            duration: 0,
            elements: 0
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert total_duration $duration)
}

def benchmark_memory_access [] {
    let start_time = (date now | into int)

    # Test memory access performance
    let result = (try {
        let array = (seq 1 10000)
        let access_start = (date now | into int)
        let sum = ($array | math sum)
        let access_end = (date now | into int)
        let access_duration = (($access_end - $access_start) | into float) / 1000000000

        {
            success: true,
            duration: $access_duration,
            sum: $sum
        }
    } catch {
        {
            success: false,
            duration: 0,
            sum: 0
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert total_duration $duration)
}

def benchmark_swap_performance [] {
    let start_time = (date now | into int)

    # Test swap performance
    let result = (try {
        let swap_info = (sys | get mem.swap)
        {
            success: true,
            total_swap: ($swap_info | get total),
            used_swap: ($swap_info | get used),
            free_swap: ($swap_info | get free)
        }
    } catch {
        {
            success: false,
            total_swap: 0,
            used_swap: 0,
            free_swap: 0
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert duration $duration)
}

def benchmark_network_connectivity [] {
    let start_time = (date now | into int)

    # Test network connectivity
    let result = (try {
        let ping_start = (date now | into int)
        ping -c 1 8.8.8.8 | ignore
        let ping_end = (date now | into int)
        let ping_duration = (($ping_end - $ping_start) | into float) / 1000000000

        {
            success: true,
            duration: $ping_duration,
            target: "8.8.8.8"
        }
    } catch {
        {
            success: false,
            duration: 0,
            target: "8.8.8.8"
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert total_duration $duration)
}

def benchmark_dns_resolution [] {
    let start_time = (date now | into int)

    # Test DNS resolution performance
    let result = (try {
        let dns_start = (date now | into int)
        nslookup google.com | ignore
        let dns_end = (date now | into int)
        let dns_duration = (($dns_end - $dns_start) | into float) / 1000000000

        {
            success: true,
            duration: $dns_duration,
            domain: "google.com"
        }
    } catch {
        {
            success: false,
            duration: 0,
            domain: "google.com"
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert total_duration $duration)
}

def benchmark_download_speed [] {
    let start_time = (date now | into int)

    # Test download speed (small file)
    let test_url = "https://httpbin.org/bytes/1024"
    let result = (try {
        let download_start = (date now | into int)
        curl -s -o /dev/null $test_url
        let download_end = (date now | into int)
        let download_duration = (($download_end - $download_start) | into float) / 1000000000

        {
            success: true,
            duration: $download_duration,
            size_bytes: 1024,
            speed_mbps: (1024 / $download_duration / 1000000)
        }
    } catch {
        {
            success: false,
            duration: 0,
            size_bytes: 0,
            speed_mbps: 0
        }
    })

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    ($result | upsert total_duration $duration)
}

def generate_performance_report [results: record] {
    print "\n(ansi green)📊 Performance Test Report(ansi reset)"
    print "(ansi yellow)==========================(ansi reset)\n"

    let total_duration = ($results | values | get duration | math sum)
    let total_tests = ($results | columns | length)
    let passed_tests = ($results | values | where success == true | length)

    print $"Total Duration: (ansi cyan)($total_duration | into string -d 2)s(ansi reset)"
    print $"Tests Run: (ansi cyan)($total_tests)(ansi reset)"
    print $"Tests Passed: (ansi green)($passed_tests)(ansi reset)"
    print $"Tests Failed: (ansi red)(($total_tests - $passed_tests))(ansi reset)\n"

    # Detailed results
    $results | each {|suite|
        let suite_name = $suite.0
        let suite_data = $suite.1
        let status = if $suite_data.success {
            "(ansi green)✅ PASS(ansi reset)"
        } else {
            "(ansi red)❌ FAIL(ansi reset)"
        }

        let formatted_name = ($suite_name | str replace "_" " " | str title-case)
        let formatted_duration = ($suite_data.duration | into string -d 2)
        print $"($formatted_name): $status ($formatted_duration)s"

        # Show detailed results for failed tests
        if not $suite_data.success {
            $suite_data.results | each {|test|
                let test_name = $test.0
                let test_data = $test.1
                if not $test_data.success {
                    print $"  └─ ($test_name): (ansi red)FAILED(ansi reset)"
                }
            }
        }
    }

    print "\n(ansi blue)💡 Performance Tips:(ansi reset)"
    print "• Consider optimizing slow configuration parsing"
    print "• Monitor system resources during builds"
    print "• Use SSD storage for better disk performance"
    print "• Ensure adequate memory for large builds"
}
