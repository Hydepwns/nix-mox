#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"

    print_status "Running test: $test_name"

    if eval "$test_command" 2>/dev/null; then
        print_success "✓ $test_name passed"
        ((TESTS_PASSED++))
    else
        print_error "✗ $test_name failed"
        ((TESTS_FAILED++))
    fi
}

# Main test function
main() {
    print_status "Testing Safe Configuration Template"
    echo

    # Test 1: Check if template directory exists
    run_test "Template directory exists" "[ -d 'modules/templates/nixos/safe-configuration' ]"

    # Test 2: Check if all required files exist
    run_test "flake.nix exists" "[ -f 'modules/templates/nixos/safe-configuration/flake.nix' ]"
    run_test "configuration.nix exists" "[ -f 'modules/templates/nixos/safe-configuration/configuration.nix' ]"
    run_test "home.nix exists" "[ -f 'modules/templates/nixos/safe-configuration/home.nix' ]"
    run_test "README.md exists" "[ -f 'modules/templates/nixos/safe-configuration/README.md' ]"
    run_test "setup.sh exists" "[ -f 'modules/templates/nixos/safe-configuration/setup.sh' ]"

    # Test 3: Check if setup script is executable
    run_test "setup.sh is executable" "[ -x 'modules/templates/nixos/safe-configuration/setup.sh' ]"

    # Test 4: Check if template is integrated into templates.nix
    run_test "Template integrated in templates.nix" "grep -q 'safe-configuration' modules/templates/templates.nix"

    # Test 5: Check if documentation is updated
    run_test "Documentation updated in USAGE.md" "grep -q 'Safe Configuration Template' docs/USAGE.md"
    run_test "Documentation updated in nixos-on-proxmox.md" "grep -q 'Safe Configuration Template' docs/guides/nixos-on-proxmox.md"

    # Test 6: Check if flake.nix has correct structure
    run_test "flake.nix has nix-mox input" "grep -q 'nix-mox' modules/templates/nixos/safe-configuration/flake.nix"
    run_test "flake.nix has home-manager input" "grep -q 'home-manager' modules/templates/nixos/safe-configuration/flake.nix"

    # Test 7: Check if configuration.nix has display safety
    run_test "configuration.nix has display manager" "grep -q 'displayManager' modules/templates/nixos/safe-configuration/configuration.nix"
    run_test "configuration.nix has desktop manager" "grep -q 'desktopManager' modules/templates/nixos/safe-configuration/configuration.nix"
    run_test "configuration.nix has nix-mox packages" "grep -q 'nix-mox.packages' modules/templates/nixos/safe-configuration/configuration.nix"

    # Test 8: Check if home.nix has nix-mox aliases
    run_test "home.nix has nix-mox dev shell aliases" "grep -q 'dev-gaming' modules/templates/nixos/safe-configuration/home.nix"

    # Test 9: Check if README.md has key features
    run_test "README.md has display safety feature" "grep -q 'Display Safety' modules/templates/nixos/safe-configuration/README.md"
    run_test "README.md has nix-mox integration feature" "grep -q 'nix-mox Integration' modules/templates/nixos/safe-configuration/README.md"

    # Test 10: Check if setup script has proper structure
    run_test "setup.sh has colored output functions" "grep -q 'print_status' modules/templates/nixos/safe-configuration/setup.sh"
    run_test "setup.sh has main function" "grep -q 'main()' modules/templates/nixos/safe-configuration/setup.sh"

    echo
    print_status "Test Summary:"
    print_success "Tests passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        print_error "Tests failed: $TESTS_FAILED"
    else
        print_success "Tests failed: $TESTS_FAILED"
    fi

    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "All tests passed! Safe Configuration Template is working correctly."
        exit 0
    else
        print_error "Some tests failed. Please check the implementation."
        exit 1
    fi
}

# Run main function
main "$@"
