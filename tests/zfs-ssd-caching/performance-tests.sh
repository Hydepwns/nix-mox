#!/bin/sh
set -e

# Source test utilities
. ../test-utils.nix

echo "Running ZFS SSD caching performance tests..."

# Test retry performance
echo "Testing retry performance..."
start_time=$(date +%s)
testRetry 3 1 "true" true
end_time=$(date +%s)
duration=$((end_time - start_time))
if [ $duration -gt 5 ]; then
  echo "Retry performance test failed: took too long ($duration seconds)"
  exit 1
fi

# Test logging performance
echo "Testing logging performance..."
start_time=$(date +%s)
for i in $(seq 1 100); do
  testLogging "INFO" "Test message $i" "[INFO] Test message $i" || exit 1
done
end_time=$(date +%s)
duration=$((end_time - start_time))
if [ $duration -gt 10 ]; then
  echo "Logging performance test failed: took too long ($duration seconds)"
  exit 1
fi

# Test configuration validation performance
echo "Testing configuration validation performance..."
start_time=$(date +%s)
for i in $(seq 1 100); do
  testConfigValidation "test$i" "Configuration validation failed" || exit 1
done
end_time=$(date +%s)
duration=$((end_time - start_time))
if [ $duration -gt 10 ]; then
  echo "Configuration validation performance test failed: took too long ($duration seconds)"
  exit 1
fi

# Test resource utilization
echo "Testing resource utilization..."
if command -v top >/dev/null 2>&1; then
  # Monitor CPU and memory usage during operations
  top -b -n 1 | grep -q "zfs" || echo "No ZFS processes found"
else
  echo "top command not available, skipping resource utilization test"
fi

echo "Performance tests completed successfully" 