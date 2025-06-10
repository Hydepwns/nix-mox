#!/bin/sh
set -e

# Source test utilities
. ./test-utils.nix

echo "Running unit tests..."

# Test configuration validation
echo "Testing configuration validation..."
testConfigValidation "rpool" "Pool name is not configured" || exit 1
testConfigValidation "/dev/nvme*n1" "Device pattern is not configured" || exit 1

# Test logging
echo "Testing logging functionality..."
testLogging "INFO" "Test message" "[INFO] Test message" || exit 1
testLogging "ERROR" "Error message" "[ERROR] Error message" || exit 1
testLogging "WARN" "Warning message" "[WARN] Warning message" || exit 1
testLogging "DEBUG" "Debug message" "[DEBUG] Debug message" || exit 1

# Test retry mechanism
echo "Testing retry mechanism..."
testRetry 3 1 "true" true || exit 1
testRetry 3 1 "false" false || exit 1

# Test device detection
echo "Testing device detection..."
if [ -b "/dev/nvme0n1" ]; then
  echo "NVMe device found"
else
  echo "No NVMe device found, skipping device tests"
fi

# Test pool operations
echo "Testing pool operations..."
if zpool list rpool >/dev/null 2>&1; then
  echo "ZFS pool found"
else
  echo "No ZFS pool found, skipping pool tests"
fi

echo "Unit tests completed successfully" 