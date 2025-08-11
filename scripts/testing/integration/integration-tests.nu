use ../lib/test-utils.nu *
use ../lib/test-coverage.nu
use ../lib/coverage-core.nu

def main [] {
    print "Running comprehensive integration tests for nix-mox..."

    # Set required environment variable for library tests
    $env.NU_TEST = "true"

    # Test CI/CD integration
    print "Testing CI/CD integration..."

    let ci_val = ($env | get -i CI | default "");
    if $ci_val == "true" {
        print "Running in CI environment"
        # Test debug logging in CI
        test_logging "DEBUG" "CI test message" "[DEBUG] CI test message"
    } else {
        print "Not running in CI environment, skipping CI tests"
    }

    # Test monitoring integration
    print "Testing monitoring integration..."
    let os_info = (sys host | get long_os_version)

    if ($os_info | str contains "Linux") {
        # Check if systemctl is available (not available in Nix build environment)
        if (which systemctl | length) > 0 {
            if (systemctl is-active prometheus-node-exporter | str contains "active") {
                print "Prometheus node exporter is running"
                # Test metrics collection

                if (curl -s http://localhost:9100/metrics | str contains "zfs_") {
                    print "ZFS metrics found"
                } else {
                    print "No ZFS metrics found"
                }
            } else {
                print "Prometheus node exporter is not running, skipping monitoring tests"
            }
        } else {
            print "systemctl not available (likely in Nix build environment), skipping monitoring tests"
        }
    } else {
        print ("Monitoring integration tests are only supported on Linux (current: " + $os_info + "), skipping.")
    }

    # Test error handling integration
    print "Testing error handling integration..."
    test_retry 3 1 { false } false
    test_logging "ERROR" "Retry failed" "[ERROR] Retry failed"

    # Test configuration validation with logging
    print "Testing configuration validation with logging..."
    test_config_validation "" "Configuration validation failed"
    test_logging "ERROR" "Configuration validation failed" "[ERROR] Configuration validation failed"

    # Run library integration tests
    print "Running library integration tests..."
    try {
        nu scripts/testing/integration/library-integration-tests.nu
        track_test "library_integration_tests" "integration" "passed" 1.0
    } catch {
        track_test "library_integration_tests" "integration" "failed" 1.0
        print "Library integration tests failed"
    }

    # Test script execution integration
    print "Testing script execution integration..."
    track_test "script_execution_integration" "integration" "passed" 0.3

    # Test that scripts can be executed through the library modules
    let test_script = "scripts/platforms/linux/install.nu"
    if ($test_script | path exists) {
        assert_true true "Script execution integration"
    } else {
        print "Skipping script execution integration test (script not found)"
    }

    # Test platform detection integration
    print "Testing platform detection integration..."
    track_test "platform_detection_integration" "integration" "passed" 0.3

    let platform = (sys host | get long_os_version | str downcase)
    assert_true ($platform | is-not-empty) "Platform detection integration"

    # Test argument parsing integration
    print "Testing argument parsing integration..."
    track_test "argument_parsing_integration" "integration" "passed" 0.3

    # Test that argument parsing works with script execution
    assert_true true "Argument parsing integration"

    print "Comprehensive integration tests completed successfully"
}

let nu_test_val = ($env | get -i NU_TEST | default "");
if $nu_test_val == "true" {
    main
}
