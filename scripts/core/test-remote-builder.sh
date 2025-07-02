#!/bin/bash

# Test Remote Nix Builder Script
# This script tests if the remote Linux builder is working correctly

set -euo pipefail

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

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if we're on macOS
check_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed to run on macOS"
    exit 1
  fi
}

# Function to check Nix configuration
check_nix_config() {
  local nix_conf="$HOME/.config/nix/nix.conf"

  if [[ ! -f $nix_conf ]]; then
    print_error "Nix configuration file not found at $nix_conf"
    print_status "Run the setup script first: ./scripts/setup-remote-builder.sh REMOTE_HOST"
    exit 1
  fi

  if ! grep -q "builders = ssh-ng://" "$nix_conf"; then
    print_error "No remote builder configuration found in $nix_conf"
    print_status "Run the setup script first: ./scripts/setup-remote-builder.sh REMOTE_HOST"
    exit 1
  fi

  print_success "Remote builder configuration found"
}

# Function to test SSH connection
test_ssh_connection() {
  print_status "Testing SSH connection to remote builder..."

  # Extract remote host from nix.conf
  local nix_conf="$HOME/.config/nix/nix.conf"
  local builder_line
  builder_line=$(grep "builders = ssh-ng://" "$nix_conf")
  local remote_host
  remote_host=$(echo "$builder_line" | sed -n 's/.*ssh-ng:\/\/[^@]*@\([^:]*\).*/\1/p')
  local remote_user
  remote_user=$(echo "$builder_line" | sed -n 's/.*ssh-ng:\/\/\([^@]*\)@.*/\1/p')
  local ssh_port
  ssh_port=$(echo "$builder_line" | sed -n 's/.*@[^:]*:\([0-9]*\).*/\1/p')

  if [[ -z $remote_host ]]; then
    print_error "Could not extract remote host from nix.conf"
    exit 1
  fi

  if [[ -z $ssh_port ]]; then
    ssh_port="22"
  fi

  print_status "Remote host: $remote_host"
  print_status "Remote user: $remote_user"
  print_status "SSH port: $ssh_port"

  if ssh -p "$ssh_port" -o ConnectTimeout=10 -o BatchMode=yes "$remote_user@$remote_host" exit 2> /dev/null; then
    print_success "SSH connection successful"
  else
    print_error "SSH connection failed"
    print_status "Please check:"
    print_status "1. Remote host is accessible"
    print_status "2. SSH key authentication is working"
    print_status "3. Remote user has proper permissions"
    exit 1
  fi
}

# Function to test simple derivation
test_simple_derivation() {
  print_status "Testing simple derivation build..."

  local test_expr
  test_expr='derivation {
        name = "remote-test";
        system = "x86_64-linux";
        builder = "/bin/sh";
        args = ["-c" "echo \"Remote builder test successful\" > $out"];
    }'

  local test_drv
  test_drv=$(nix-instantiate --expr "$test_expr" 2> /dev/null || true)

  if [[ -n $test_drv ]]; then
    print_status "Testing build on remote machine..."
    if nix-store --realise "$test_drv" --dry-run 2>&1 | grep -q "will be built"; then
      print_success "Remote builder is working correctly"
      print_status "Build will be performed on remote machine"
    else
      print_warning "Remote builder may not be working as expected"
      print_status "Build might be performed locally"
    fi
  else
    print_error "Could not create test derivation"
    exit 1
  fi
}

# Function to test actual build
test_actual_build() {
  print_status "Testing actual build on remote machine..."

  local test_expr
  test_expr="derivation {
        name = \"remote-build-test\";
        system = \"x86_64-linux\";
        builder = \"/bin/sh\";
        args = [\"-c\" \"echo \\\"Build completed at $(date)\\\" > \$out\"];
    }"

  local test_drv
  test_drv=$(nix-instantiate --expr "$test_expr")

  print_status "Building test derivation..."
  local result
  result=$(nix-store --realise "$test_drv")

  if [[ -n $result ]]; then
    print_success "Build completed successfully!"
    print_status "Result: $result"
    print_status "Content: $(cat "$result")"

    # Cleanup
    nix-store --delete "$result" 2> /dev/null || true
    print_status "Cleaned up test build"
  else
    print_error "Build failed"
    exit 1
  fi
}

# Function to show builder status
show_builder_status() {
  print_status "Current builder configuration:"
  echo
  cat ~/.config/nix/nix.conf | grep -A 5 -B 5 "builders"
  echo

  print_status "Available builders:"
  nix show-config | grep -A 10 "builders" || print_warning "No builder configuration found"
}

# Function to test your project builds
test_project_builds() {
  print_status "Testing your project builds..."

  # Check if we're in a nix-mox project
  if [[ -f "flake.nix" ]]; then
    print_status "Found flake.nix, testing project builds..."

    # Test x86_64-linux build
    if nix eval .#packages.x86_64-linux.default 2> /dev/null; then
      print_status "Testing x86_64-linux build..."
      if nix build .#packages.x86_64-linux.default --dry-run 2>&1 | grep -q "will be built"; then
        print_success "x86_64-linux build will use remote builder"
      else
        print_warning "x86_64-linux build may not use remote builder"
      fi
    else
      print_warning "No x86_64-linux packages found"
    fi

    # Test aarch64-linux build
    if nix eval .#packages.aarch64-linux.default 2> /dev/null; then
      print_status "Testing aarch64-linux build..."
      if nix build .#packages.aarch64-linux.default --dry-run 2>&1 | grep -q "will be built"; then
        print_success "aarch64-linux build will use remote builder"
      else
        print_warning "aarch64-linux build may not use remote builder"
      fi
    else
      print_warning "No aarch64-linux packages found"
    fi
  else
    print_warning "No flake.nix found in current directory"
  fi
}

# Main function
main() {
  print_status "Testing remote Nix builder setup..."

  check_macos
  check_nix_config
  test_ssh_connection
  test_simple_derivation

  echo
  print_status "Do you want to run an actual build test? (y/N)"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    test_actual_build
  fi

  echo
  show_builder_status

  echo
  test_project_builds

  echo
  print_success "Remote builder test complete!"
  print_status "If all tests passed, you can now build Linux packages from macOS"
}

# Run main function
main
