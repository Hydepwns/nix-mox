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

  if eval "$test_command" 2> /dev/null; then
    print_success "✓ $test_name passed"
    ((TESTS_PASSED++))
  else
    print_error "✗ $test_name failed"
    ((TESTS_FAILED++))
  fi
}

# Main test function
main() {
  print_status "Testing Safe Configuration Template with Fragment System"
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

  # Test 4: Check if fragment system exists
  run_test "Base common.nix exists" "[ -f 'modules/templates/base/common.nix' ]"
  run_test "Common fragments directory exists" "[ -d 'modules/templates/base/common' ]"
  run_test "Networking fragment exists" "[ -f 'modules/templates/base/common/networking.nix' ]"
  run_test "Display fragment exists" "[ -f 'modules/templates/base/common/display.nix' ]"
  run_test "Packages fragment exists" "[ -f 'modules/templates/base/common/packages.nix' ]"
  run_test "Programs fragment exists" "[ -f 'modules/templates/base/common/programs.nix' ]"
  run_test "Services fragment exists" "[ -f 'modules/templates/base/common/services.nix' ]"
  run_test "Nix settings fragment exists" "[ -f 'modules/templates/base/common/nix-settings.nix' ]"
  run_test "System fragment exists" "[ -f 'modules/templates/base/common/system.nix' ]"

  # Test 5: Check if template imports from fragment system
  run_test "Template imports base common.nix" "grep -q 'base/common.nix' modules/templates/nixos/safe-configuration/configuration.nix"

  # Test 6: Check if flake.nix has correct structure for fragment system
  run_test "flake.nix has nix-mox input" "grep -q 'nix-mox' modules/templates/nixos/safe-configuration/flake.nix"
  run_test "flake.nix has home-manager input" "grep -q 'home-manager' modules/templates/nixos/safe-configuration/flake.nix"
  run_test "flake.nix has flake-utils" "grep -q 'flake-utils' modules/templates/nixos/safe-configuration/flake.nix"

  # Test 7: Check if configuration.nix uses fragment system properly
  run_test "configuration.nix imports base common" "grep -q 'base/common.nix' modules/templates/nixos/safe-configuration/configuration.nix"
  run_test "configuration.nix has minimal overrides" "grep -q 'networking.hostName' modules/templates/nixos/safe-configuration/configuration.nix"
  run_test "configuration.nix has user definition" "grep -q 'users.users' modules/templates/nixos/safe-configuration/configuration.nix"

  # Test 8: Check if home.nix has nix-mox aliases
  run_test "home.nix has nix-mox dev shell aliases" "grep -q 'dev-gaming' modules/templates/nixos/safe-configuration/home.nix"

  # Test 9: Check if README.md has key features
  run_test "README.md has display safety feature" "grep -q 'Display Safety' modules/templates/nixos/safe-configuration/README.md"
  run_test "README.md has nix-mox integration feature" "grep -q 'nix-mox Integration' modules/templates/nixos/safe-configuration/README.md"

  # Test 10: Check if setup script has proper structure for fragment system
  run_test "setup.sh has colored output functions" "grep -q 'print_status' modules/templates/nixos/safe-configuration/setup.sh"
  run_test "setup.sh has main function" "grep -q 'main()' modules/templates/nixos/safe-configuration/setup.sh"
  run_test "setup.sh creates config directory structure" "grep -q 'mkdir -p.*nixos.*home.*hardware' modules/templates/nixos/safe-configuration/setup.sh"
  run_test "setup.sh generates config/default.nix" "grep -q 'config/default.nix' modules/templates/nixos/safe-configuration/setup.sh"

  # Test 11: Check if base common.nix imports all fragments
  run_test "base common.nix imports networking fragment" "grep -q 'networking.nix' modules/templates/base/common.nix"
  run_test "base common.nix imports display fragment" "grep -q 'display.nix' modules/templates/base/common.nix"
  run_test "base common.nix imports packages fragment" "grep -q 'packages.nix' modules/templates/base/common.nix"

  # Test 12: Check if fragments have correct structure
  run_test "networking fragment has correct structure" "grep -q 'networking = {' modules/templates/base/common/networking.nix"
  run_test "display fragment has correct structure" "grep -q 'services.xserver' modules/templates/base/common/display.nix"
  run_test "packages fragment has nix-mox packages" "grep -q 'nix-mox.packages' modules/templates/base/common/packages.nix"

  # Test 13: Check messaging functionality
  run_test "messaging fragment exists" "[ -f 'modules/templates/base/common/messaging.nix' ]"
  run_test "base common.nix imports messaging fragment" "grep -q 'messaging.nix' modules/templates/base/common.nix"
  run_test "messaging fragment has Signal Desktop" "grep -q 'signal-desktop' modules/templates/base/common/messaging.nix"
  run_test "messaging fragment has Telegram Desktop" "grep -q 'telegram-desktop' modules/templates/base/common/messaging.nix"
  run_test "messaging fragment has Discord" "grep -q 'discord' modules/templates/base/common/messaging.nix"
  run_test "messaging fragment has Slack" "grep -q 'slack' modules/templates/base/common/messaging.nix"
  run_test "messaging fragment has dbus configuration" "grep -q 'dbus.enable' modules/templates/base/common/messaging.nix"
  run_test "messaging fragment has gvfs configuration" "grep -q 'gvfs.enable' modules/templates/base/common/messaging.nix"
  run_test "messaging fragment has PipeWire configuration" "grep -q 'pipewire' modules/templates/base/common/messaging.nix"

  # Test 14: Check communication packages module
  run_test "communication packages module exists" "[ -f 'modules/packages/productivity/communication.nix' ]"
  run_test "productivity index includes communication" "grep -q 'communication = import' modules/packages/productivity/index.nix"
  run_test "communication module has Signal Desktop" "grep -q 'signal-desktop' modules/packages/productivity/communication.nix"
  run_test "communication module has Telegram Desktop" "grep -q 'telegram-desktop' modules/packages/productivity/communication.nix"

  # Test 15: Check safe configuration messaging integration
  run_test "safe configuration has Signal Desktop" "grep -q 'signal-desktop' modules/templates/platforms/nixos/safe-configuration/configuration.nix"
  run_test "safe configuration has Telegram Desktop" "grep -q 'telegram-desktop' modules/templates/platforms/nixos/safe-configuration/configuration.nix"
  run_test "safe configuration has messaging firewall ports" "grep -q '3478.*3479' modules/templates/platforms/nixos/safe-configuration/configuration.nix"
  run_test "safe configuration has dbus packages" "grep -q 'dbus.packages' modules/templates/platforms/nixos/safe-configuration/configuration.nix"
  run_test "safe home configuration has messaging programs" "grep -q 'dconf.enable' modules/templates/platforms/nixos/safe-configuration/home.nix"
  run_test "safe home configuration has xdg mimeApps" "grep -q 'mimeApps' modules/templates/platforms/nixos/safe-configuration/home.nix"

  # Test 16: Check setup script messaging options
  run_test "setup script has messaging prompts" "grep -q 'Enable messaging applications' modules/templates/platforms/nixos/safe-configuration/setup.sh"
  run_test "setup script has video calling prompts" "grep -q 'Enable video calling applications' modules/templates/platforms/nixos/safe-configuration/setup.sh"
  run_test "setup script has email client prompts" "grep -q 'Enable email clients' modules/templates/platforms/nixos/safe-configuration/setup.sh"
  run_test "setup script generates messaging configuration" "grep -q 'Messaging and communication services' modules/templates/platforms/nixos/safe-configuration/setup.sh"

  # Test 17: Check if config directory structure is properly organized
  run_test "config directory exists" "[ -d 'config' ]"
  run_test "config/default.nix exists" "[ -f 'config/default.nix' ]"
  run_test "config/nixos directory exists" "[ -d 'config/nixos' ]"
  run_test "config/home directory exists" "[ -d 'config/home' ]"
  run_test "config/hardware directory exists" "[ -d 'config/hardware' ]"

  echo
  print_status "Test Summary:"
  print_success "Tests passed: $TESTS_PASSED"
  if [ $TESTS_FAILED -gt 0 ]; then
    print_error "Tests failed: $TESTS_FAILED"
  else
    print_success "Tests failed: $TESTS_FAILED"
  fi

  if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed! Safe Configuration Template with Fragment System is working correctly."
    exit 0
  else
    print_error "Some tests failed. Please check the implementation."
    exit 1
  fi
}

# Run main function
main "$@"
