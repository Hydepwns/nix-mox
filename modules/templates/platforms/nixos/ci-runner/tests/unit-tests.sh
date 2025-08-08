#!/usr/bin/env bash
set -e

# shellcheck disable=SC1091
# shellcheck source=./test-utils.sh
. ./test-utils.sh

echo "Running unit tests..."

# Test job queue
echo "Testing job queue..."
testJobQueue "test-job" "test-job" || exit 1

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

# Test parallel execution
echo "Testing parallel execution..."
testParallelExecution "echo test1" "echo test2" 2 || exit 1

echo "Unit tests completed successfully"
