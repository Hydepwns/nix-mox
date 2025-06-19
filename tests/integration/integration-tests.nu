use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *
use ../lib/coverage-core.nu *

def main [] {
    print "Running ZFS SSD caching integration tests..."

    # Test CI/CD integration
    print "Testing CI/CD integration..."
    if $env.CI? == "true" {
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

    print "Integration tests completed successfully"
}

if ($env.NU_TEST? == "true") {
    main
}
main
