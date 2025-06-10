#!/bin/sh
set -e

# Source test utilities
. ../test-utils.nix

echo "Running ZFS SSD caching integration tests..."

# Test CI/CD integration
echo "Testing CI/CD integration..."
if [ "$CI" = "true" ]; then
  echo "Running in CI environment"
  # Test debug logging in CI
  testLogging "DEBUG" "CI test message" "[DEBUG] CI test message" || exit 1
else
  echo "Not running in CI environment, skipping CI tests"
fi

# Test monitoring integration
echo "Testing monitoring integration..."
if systemctl is-active prometheus-node-exporter >/dev/null 2>&1; then
  echo "Prometheus node exporter is running"
  # Test metrics collection
  curl -s http://localhost:9100/metrics | grep -q "zfs_" || exit 1
else
  echo "Prometheus node exporter is not running, skipping monitoring tests"
fi

# Test error handling integration
echo "Testing error handling integration..."
# Test retry with logging
testRetry 3 1 "false" false || exit 1
testLogging "ERROR" "Retry failed" "[ERROR] Retry failed" || exit 1

# Test configuration validation with logging
echo "Testing configuration validation with logging..."
testConfigValidation "" "Configuration validation failed" || exit 1
testLogging "ERROR" "Configuration validation failed" "[ERROR] Configuration validation failed" || exit 1

echo "Integration tests completed successfully" 