#!/bin/sh
set -e

# shellcheck source=./test-utils.nix
. ./test-utils.nix

echo "Running integration tests..."

# Test job queue with logging
echo "Testing job queue with logging..."
testJobQueue "test-job" "test-job" || exit 1
testLogging "INFO" "Job queued" "[INFO] Job queued" || exit 1

# Test parallel execution with retry
echo "Testing parallel execution with retry..."
testParallelExecution "echo test1" "echo test2" 2 || exit 1
testRetry 3 1 "true" true || exit 1

# Test logging with different levels
echo "Testing logging with different levels..."
testLogging "INFO" "Job started" "[INFO] Job started" || exit 1
testLogging "WARN" "Job delayed" "[WARN] Job delayed" || exit 1
testLogging "ERROR" "Job failed" "[ERROR] Job failed" || exit 1
testLogging "DEBUG" "Job details" "[DEBUG] Job details" || exit 1

# Test retry with logging
echo "Testing retry with logging..."
testRetry 3 1 "false" false || exit 1
testLogging "ERROR" "Retry failed" "[ERROR] Retry failed" || exit 1

echo "Integration tests completed successfully"
