#!/bin/bash
# Test suite for nix-mox script

set -euo pipefail

# Source the common functions
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test CI mode detection
test_ci_mode() {
    echo "Testing CI mode detection..."
    
    # Test with CI=true
    export CI=true
    output=$("$SCRIPTS_DIR/scripts/nix-mox" --script install --dry-run 2>&1)
    if ! echo "$output" | grep -q "Running in CI mode"; then
        echo "❌ CI mode detection test failed"
        exit 1
    fi
    
    # Test without CI=true
    unset CI
    output=$("$SCRIPTS_DIR/scripts/nix-mox" --script install --dry-run 2>&1)
    if echo "$output" | grep -q "Running in CI mode"; then
        echo "❌ CI mode detection test failed (should not detect CI mode)"
        exit 1
    fi
    
    echo "✅ CI mode detection test passed"
}

# Test parallel execution
test_parallel_execution() {
    echo "Testing parallel execution..."
    
    export CI=true
    output=$("$SCRIPTS_DIR/scripts/nix-mox" --script install --parallel --dry-run 2>&1)
    if ! echo "$output" | grep -q "Running platform scripts in parallel"; then
        echo "❌ Parallel execution test failed"
        exit 1
    fi
    
    echo "✅ Parallel execution test passed"
}

# Run all tests
echo "Starting nix-mox tests..."
test_ci_mode
test_parallel_execution
echo "All nix-mox tests passed! 🎉" 