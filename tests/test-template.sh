#!/bin/sh
set -e

# Source test utilities
. ./test-utils.nix

echo "Running tests for component: ${COMPONENT_NAME}"

# Unit Tests
echo "Running unit tests..."
runUnitTests "testScript=./unit-tests.sh dependencies=[]"

# Integration Tests
echo "Running integration tests..."
runIntegrationTests "testScript=./integration-tests.sh dependencies=[]"

# Performance Tests
echo "Running performance tests..."
runPerformanceTests "testScript=./performance-tests.sh dependencies=[]"

echo "All tests completed successfully" 