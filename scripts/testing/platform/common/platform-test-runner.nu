#!/usr/bin/env nu
# Common platform test runner for nix-mox
# Runs platform-specific tests across all supported platforms

use ../../../lib/platform.nu *
use ../../../lib/logging.nu *
use ../../../lib/validators.nu *

# Platform test registry
const PLATFORM_TESTS = {
    linux: [
        "../linux/nixos-tests.nu",
        "../linux/systemd-tests.nu", 
        "../linux/package-manager-tests.nu"
    ],
    macos: [
        "../macos/homebrew-tests.nu",
        "../macos/launchd-tests.nu",
        "../macos/xcode-tests.nu"
    ],
    windows: [
        "../windows/powershell-tests.nu",
        "../windows/package-manager-tests.nu",
        "../windows/registry-tests.nu"
    ]
}

# Run platform-specific tests
export def run_platform_tests [
    --platform: string = "auto",
    --parallel: bool = true,
    --verbose: bool = false
] {
    if $verbose { $env.LOG_LEVEL = "DEBUG" }
    
    banner "Running platform-specific tests" --context "platform-tests"
    
    # Determine target platform
    let target_platform = if $platform == "auto" {
        (get_platform).normalized
    } else {
        $platform
    }
    
    info $"Target platform: ($target_platform)" --context "platform-tests"
    
    # Get platform test files
    let test_files = ($PLATFORM_TESTS | get $ -otarget_platform | default [])
    
    if ($test_files | length) == 0 {
        warn $"No tests defined for platform: ($target_platform)" --context "platform-tests"
        return {
            platform: $target_platform,
            tests_run: 0,
            passed: 0,
            failed: 0,
            success: true
        }
    }
    
    info $"Found ($test_files | length) test files for ($target_platform)" --context "platform-tests"
    
    mut results = []
    mut total_passed = 0
    mut total_failed = 0
    
    for test_file in $test_files {
        let test_name = ($test_file | path basename | str replace ".nu" "")
        info $"Running ($test_name)..." --context "platform-tests"
        
        try {
            if ($test_file | path exists) {
                let result = (^nu $test_file | complete)
                if $result.exit_code == 0 {
                    success $"✅ ($test_name) passed" --context "platform-tests"
                    $total_passed += 1
                    $results = ($results | append {
                        name: $test_name,
                        status: "passed",
                        exit_code: $result.exit_code
                    })
                } else {
                    error $"❌ ($test_name) failed (exit: ($result.exit_code))" --context "platform-tests"
                    $total_failed += 1
                    $results = ($results | append {
                        name: $test_name,
                        status: "failed",
                        exit_code: $result.exit_code,
                        stderr: $result.stderr
                    })
                }
            } else {
                warn $"⚠️ ($test_name) not found, skipping" --context "platform-tests"
                $results = ($results | append {
                    name: $test_name,
                    status: "skipped",
                    reason: "file_not_found"
                })
            }
        } catch { | err|
            error $"❌ ($test_name) crashed: ($err.msg)" --context "platform-tests"
            $total_failed += 1
            $results = ($results | append {
                name: $test_name,
                status: "crashed",
                error: $err.msg
            })
        }
    }
    
    let total_tests = $total_passed + $total_failed
    let success_rate = if $total_tests > 0 { 
        ($total_passed * 100 / $total_tests | math round) 
    } else { 
        100 
    }
    
    section "Platform Test Summary" --context "platform-tests"
    summary $"($target_platform) platform tests" $total_passed $total_tests --context "platform-tests"
    info $"Success rate: ($success_rate)%" --context "platform-tests"
    
    {
        platform: $target_platform,
        tests_run: $total_tests,
        passed: $total_passed,
        failed: $total_failed,
        success_rate: $success_rate,
        success: ($total_failed == 0),
        results: $results
    }
}

# Run tests for all platforms
export def run_all_platform_tests [
    --parallel: bool = false,
    --verbose: bool = false
] {
    banner "Running tests for all platforms" --context "platform-tests"
    
    let platforms = ["linux", "macos", "windows"]
    mut all_results = []
    
    for platform in $platforms {
        section $"Testing ($platform) platform" --context "platform-tests"
        let result = (run_platform_tests --platform $platform --verbose $verbose)
        $all_results = ($all_results | append $result)
    }
    
    # Summary across all platforms
    let total_tests = ($all_results | get tests_run | math sum)
    let total_passed = ($all_results | get passed | math sum)
    let total_failed = ($all_results | get failed | math sum)
    
    section "Cross-Platform Test Summary" --context "platform-tests"
    summary "All platform tests" $total_passed $total_tests --context "platform-tests"
    
    for result in $all_results {
        let status = if $result.success { "✅" } else { "❌" }
        info $"($status) ($result.platform): ($result.passed)/($result.tests_run)" --context "platform-tests"
    }
    
    {
        total_tests: $total_tests,
        total_passed: $total_passed,
        total_failed: $total_failed,
        success: ($total_failed == 0),
        platform_results: $all_results
    }
}

# Show available platform tests
export def show_platform_tests [] {
    banner "Available platform tests" --context "platform-tests"
    
    for platform in ($PLATFORM_TESTS | columns) {
        section $"($platform | str upcase) tests" --context "platform-tests"
        let tests = ($PLATFORM_TESTS | get $platform)
        
        for test in $tests {
            let test_name = ($test | path basename | str replace ".nu" "")
            let exists = ($test | path exists)
            let status = if $exists { "✅" } else { "⚠️" }
            info $"  ($status) ($test_name)" --context "platform-tests"
        }
    }
}

# Main dispatcher
export def main [command: string = "current", ...args] {
    match $command {
        "current" => (run_platform_tests ...$args),
        "all" => (run_all_platform_tests ...$args),
        "list" => (show_platform_tests),
        _ => {
            error $"Unknown command: ($command)" --context "platform-tests"
            info "Available commands: current, all, list" --context "platform-tests"
        }
    }
}

# Show help
export def show_help [] {
    print "Platform Test Runner"
    print "==================="
    print ""
    print "Commands:"
    print "  current [--platform <platform>] [--parallel] [--verbose]  - Run tests for current/specified platform"
    print "  all [--parallel] [--verbose]                              - Run tests for all platforms"  
    print "  list                                                       - Show available platform tests"
    print ""
    print "Examples:"
    print "  nu platform-test-runner.nu current                       - Run current platform tests"
    print "  nu platform-test-runner.nu current --platform linux      - Run Linux tests specifically"
    print "  nu platform-test-runner.nu all                           - Run all platform tests"
    print "  nu platform-test-runner.nu list                          - List available tests"
}

# If script run directly with "help", show help
if ($env.SCRIPT_ARGS? | default [] | any { $it == "help" }) {
    show_help
}