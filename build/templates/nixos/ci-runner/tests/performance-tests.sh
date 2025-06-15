#!/bin/sh
set -e

# Source test utilities
. ./test-utils.nix

echo "Running performance tests..."

# Test job queue performance
echo "Testing job queue performance..."
start_time=$(date +%s)
for i in $(seq 1 100); do
  testJobQueue "test-job-$i" "test-job-$i" || exit 1
done
end_time=$(date +%s)
duration=$((end_time - start_time))
if [ $duration -gt 10 ]; then
  echo "Job queue performance test failed: took too long ($duration seconds)"
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

# Test parallel execution performance
echo "Testing parallel execution performance..."
start_time=$(date +%s)
testParallelExecution "echo test1" "echo test2" "echo test3" "echo test4" 2 || exit 1
end_time=$(date +%s)
duration=$((end_time - start_time))
if [ $duration -gt 5 ]; then
  echo "Parallel execution performance test failed: took too long ($duration seconds)"
  exit 1
fi

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

echo "Performance tests completed successfully" 