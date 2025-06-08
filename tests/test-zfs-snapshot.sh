#!/bin/bash
# Test suite for zfs-snapshot.sh

set -euo pipefail

# Source the common functions
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPTS_DIR/scripts/linux/_common.sh"

# Mock ZFS commands for testing
mock_zfs() {
    case "$1" in
        "list")
            if [[ "$*" == *"-t snapshot"* ]]; then
                echo "rpool@auto-2024-03-20-1200"
                echo "rpool@auto-2024-03-19-1200"
                echo "rpool@auto-2024-03-18-1200"
            fi
            ;;
        "snapshot")
            echo "Created snapshot rpool@auto-$(date +%Y-%m-%d-%H%M)"
            ;;
        "destroy")
            echo "Destroyed snapshot $2"
            ;;
        *)
            echo "Unknown zfs command: $1"
            exit 1
            ;;
    esac
}

# Test dry run mode
test_dry_run() {
    echo "Testing dry run mode..."
    
    # Mock the zfs command
    export PATH="$SCRIPTS_DIR/tests:$PATH"
    echo '#!/bin/bash
    mock_zfs "$@"' > "$SCRIPTS_DIR/tests/zfs"
    chmod +x "$SCRIPTS_DIR/tests/zfs"
    
    # Run the script in dry run mode
    output=$("$SCRIPTS_DIR/scripts/linux/zfs-snapshot.sh" --dry-run 2>&1)
    
    # Check for dry run message
    if ! echo "$output" | grep -q "Dry run"; then
        echo "❌ Dry run test failed"
        exit 1
    fi
    
    echo "✅ Dry run test passed"
}

# Test snapshot creation
test_snapshot_creation() {
    echo "Testing snapshot creation..."
    
    # Run the script
    output=$("$SCRIPTS_DIR/scripts/linux/zfs-snapshot.sh" 2>&1)
    
    # Check for success message
    if ! echo "$output" | grep -q "Successfully created snapshot"; then
        echo "❌ Snapshot creation test failed"
        exit 1
    fi
    
    echo "✅ Snapshot creation test passed"
}

# Cleanup
cleanup() {
    rm -f "$SCRIPTS_DIR/tests/zfs"
}

trap cleanup EXIT

# Run all tests
echo "Starting ZFS snapshot tests..."
test_dry_run
test_snapshot_creation
echo "All ZFS snapshot tests passed! 🎉" 