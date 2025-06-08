#!/bin/bash
# Test suite for _common.sh functions

set -euo pipefail

# Source the common functions
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPTS_DIR/scripts/linux/_common.sh"

# Test log functions
test_log_functions() {
    echo "Testing log functions..."
    
    # Test log_info
    log_info "This is an info message" > /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ log_info test failed"
        exit 1
    fi
    
    # Test log_warn
    log_warn "This is a warning message" > /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ log_warn test failed"
        exit 1
    fi
    
    # Test log_error
    log_error "This is an error message" > /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ log_error test failed"
        exit 1
    fi
    
    echo "✅ Log function tests passed"
}

# Test check_root function
test_check_root() {
    echo "Testing check_root function..."
    
    # This should fail when not run as root
    if check_root 2>/dev/null; then
        echo "❌ check_root test failed (should fail when not root)"
        exit 1
    fi
    
    echo "✅ check_root test passed"
}

# Run all tests
echo "Starting tests..."
test_log_functions
test_check_root
echo "All tests passed! 🎉" 