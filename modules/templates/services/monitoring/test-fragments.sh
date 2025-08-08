#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
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
  print_status "Testing Monitoring Template with Fragment System"
  echo

  # Test 1: Check if monitoring directory exists
  run_test "Monitoring directory exists" "[ -d 'modules/templates/monitoring' ]"

  # Test 2: Check if fragment system exists
  run_test "Fragment system exists" "[ -d 'modules/templates/monitoring/fragments' ]"
  run_test "Main monitoring.nix exists" "[ -f 'modules/templates/monitoring/monitoring.nix' ]"
  run_test "Prometheus fragment exists" "[ -f 'modules/templates/monitoring/fragments/prometheus.nix' ]"
  run_test "Grafana fragment exists" "[ -f 'modules/templates/monitoring/fragments/grafana.nix' ]"
  run_test "Node exporter fragment exists" "[ -f 'modules/templates/monitoring/fragments/node-exporter.nix' ]"
  run_test "Alertmanager fragment exists" "[ -f 'modules/templates/monitoring/fragments/alertmanager.nix' ]"

  # Test 3: Check if examples exist
  run_test "Examples directory exists" "[ -d 'modules/templates/monitoring/examples' ]"
  run_test "Complete stack example exists" "[ -f 'modules/templates/monitoring/examples/complete-stack.nix' ]"
  run_test "Prometheus only example exists" "[ -f 'modules/templates/monitoring/examples/prometheus-only.nix' ]"
  run_test "Grafana only example exists" "[ -f 'modules/templates/monitoring/examples/grafana-only.nix' ]"

  # Test 4: Check if documentation exists
  run_test "README.md exists" "[ -f 'modules/templates/monitoring/README.md' ]"
  run_test "README-fragments.md exists" "[ -f 'modules/templates/monitoring/README-fragments.md' ]"

  # Test 5: Check if old files are cleaned up
  run_test "Old prometheus.nix is removed" "[ ! -f 'modules/templates/monitoring/prometheus.nix' ]"
  run_test "Old grafana.nix is removed" "[ ! -f 'modules/templates/monitoring/grafana/grafana.nix' ]"

  # Test 6: Check if main monitoring.nix imports all fragments
  run_test "Main monitoring.nix imports prometheus fragment" "grep -q 'prometheus.nix' modules/templates/monitoring/monitoring.nix"
  run_test "Main monitoring.nix imports grafana fragment" "grep -q 'grafana.nix' modules/templates/monitoring/monitoring.nix"
  run_test "Main monitoring.nix imports node-exporter fragment" "grep -q 'node-exporter.nix' modules/templates/monitoring/monitoring.nix"
  run_test "Main monitoring.nix imports alertmanager fragment" "grep -q 'alertmanager.nix' modules/templates/monitoring/monitoring.nix"

  # Test 7: Check if fragments have correct structure
  run_test "Prometheus fragment has services.prometheus" "grep -q 'services.prometheus' modules/templates/monitoring/fragments/prometheus.nix"
  run_test "Grafana fragment has services.grafana" "grep -q 'services.grafana' modules/templates/monitoring/fragments/grafana.nix"
  run_test "Node exporter fragment has services.prometheus.exporters.node" "grep -q 'services.prometheus.exporters.node' modules/templates/monitoring/fragments/node-exporter.nix"
  run_test "Alertmanager fragment has services.prometheus.alertmanager" "grep -q 'services.prometheus.alertmanager' modules/templates/monitoring/fragments/alertmanager.nix"

  # Test 8: Check if examples use fragment system
  run_test "Complete stack example imports fragments" "grep -q 'fragments/' modules/templates/monitoring/examples/complete-stack.nix"
  run_test "Prometheus only example imports fragments" "grep -q 'fragments/' modules/templates/monitoring/examples/prometheus-only.nix"
  run_test "Grafana only example imports fragments" "grep -q 'fragments/' modules/templates/monitoring/examples/grafana-only.nix"

  # Test 9: Check if README mentions fragment system
  run_test "README.md mentions fragment system" "grep -q 'fragment system' modules/templates/monitoring/README.md"
  run_test "README-fragments.md exists and is comprehensive" "[ -s 'modules/templates/monitoring/README-fragments.md' ]"

  # Test 10: Check if grafana directory still has dashboards
  run_test "Grafana dashboards directory exists" "[ -d 'modules/templates/monitoring/grafana/dashboards' ]"
  run_test "Sample dashboard exists" "[ -f 'modules/templates/monitoring/grafana/dashboards/node-exporter-sample.json' ]"

  echo
  print_status "Test Summary:"
  print_success "Tests passed: $TESTS_PASSED"
  if [ $TESTS_FAILED -gt 0 ]; then
    print_error "Tests failed: $TESTS_FAILED"
  else
    print_success "Tests failed: $TESTS_FAILED"
  fi

  if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed! Monitoring Template with Fragment System is working correctly."
    exit 0
  else
    print_error "Some tests failed. Please check the implementation."
    exit 1
  fi
}

# Run main function
main "$@"
