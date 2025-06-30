#!/usr/bin/env bash

# Local CI Testing Script for nix-mox
# This script simulates the GitHub Actions workflow locally

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Nix is installed
check_nix() {
    if ! command -v nix &> /dev/null; then
        log_error "Nix is not installed. Please install Nix first."
        exit 1
    fi
    log_success "Nix is installed: $(nix --version)"
}

# Check if we're in a Nix flake
check_flake() {
    if [ ! -f "flake.nix" ]; then
        log_error "Not in a Nix flake directory. Please run this script from the project root."
        exit 1
    fi
    log_success "Found flake.nix"
}

# Simulate build job
build_packages() {
    log_info "Running build_packages job..."

    # Get current system
    local current_system
    current_system=$(uname -s)
    local current_arch
    current_arch=$(uname -m)
    local nix_system=""

    # Map to Nix system format
    case "$current_system" in
        "Darwin")
            case "$current_arch" in
                "arm64") nix_system="aarch64-darwin" ;;
                "x86_64") nix_system="x86_64-darwin" ;;
                *) log_error "Unsupported macOS architecture: $current_arch"; return 1 ;;
            esac
            ;;
        "Linux")
            case "$current_arch" in
                "x86_64") nix_system="x86_64-linux" ;;
                "aarch64") nix_system="aarch64-linux" ;;
                *) log_error "Unsupported Linux architecture: $current_arch"; return 1 ;;
            esac
            ;;
        *)
            log_error "Unsupported operating system: $current_system"
            return 1
            ;;
    esac

    log_info "Detected system: $nix_system"

    # Check Nix version
    local nix_version
    nix_version=$(nix --version | head -n1)
    log_info "Using Nix: $nix_version"

    # Build packages based on platform
    if [[ "$current_system" == "Linux" ]]; then
        # Linux-specific packages
        log_info "Building Linux-specific packages..."
        if nix build .#proxmox-update .#vzdump-backup .#zfs-snapshot .#nixos-flake-update --system "$nix_system" --accept-flake-config; then
            log_success "Successfully built Linux packages with Nix $nix_version"
        else
            log_error "Failed to build Linux packages with Nix $nix_version"
            return 1
        fi
    elif [[ "$current_system" == "Darwin" ]]; then
        # macOS-specific packages
        log_info "Building macOS-specific packages..."
        if nix build .#homebrew-setup .#macos-maintenance .#xcode-setup .#security-audit --system "$nix_system" --accept-flake-config; then
            log_success "Successfully built macOS packages with Nix $nix_version"
        else
            log_error "Failed to build macOS packages with Nix $nix_version"
            return 1
        fi
    fi

    # Build common packages (available on all platforms)
    log_info "Building common packages..."
    if nix build .#install .#uninstall --system "$nix_system" --accept-flake-config; then
        log_success "Successfully built common packages with Nix $nix_version"
    else
        log_error "Failed to build common packages with Nix $nix_version"
        return 1
    fi

    log_success "build_packages job completed successfully"
}

# Simulate test job
run_tests() {
    log_info "Running test job..."

    # Run nix flake check as specified in CI
    if nix flake check --accept-flake-config --impure; then
        log_success "nix flake check passed"
    else
        log_error "nix flake check failed"
        return 1
    fi

    # Run additional tests using Makefile targets
    log_info "Running unit tests..."
    if make unit; then
        log_success "Unit tests passed"
    else
        log_error "Unit tests failed"
        return 1
    fi

    log_info "Running integration tests..."
    if make integration; then
        log_success "Integration tests passed"
    else
        log_error "Integration tests failed"
        return 1
    fi

    log_info "Running full test suite..."
    if make test; then
        log_success "Full test suite passed"
    else
        log_error "Full test suite failed"
        return 1
    fi

    log_success "test job completed successfully"
}

# Simulate release job (dry run)
release_dry_run() {
    log_info "Running release job (dry run)..."

    # Check if we're on a tag (simulate release condition)
    if git describe --tags --exact-match 2>/dev/null; then
        log_info "Running on tag: $(git describe --tags --exact-match)"

        # Check if build artifacts exist
        if [ -d "result" ] || [ -d "result-*" ]; then
            log_success "Build artifacts found"
        else
            log_warning "No build artifacts found for release"
        fi
    else
        log_info "Not on a tag, skipping release job"
    fi

    log_success "release job (dry run) completed"
}

# Run individual checks
run_checks() {
    log_info "Running individual checks..."

    # Check all flake outputs
    log_info "Checking flake outputs..."
    if nix flake show; then
        log_success "Flake outputs are valid"
    else
        log_error "Flake outputs check failed"
        return 1
    fi

    # Check devshells
    log_info "Checking devshells..."
    if nix develop --command echo "Devshell is valid"; then
        log_success "Devshells are valid"
    else
        log_error "Devshells check failed"
        return 1
    fi

    # Check formatter
    log_info "Checking formatter..."
    if nix run .#formatter -- --help >/dev/null 2>&1; then
        log_success "Formatter is available"
    else
        log_error "Formatter check failed"
        return 1
    fi

    log_success "All checks passed"
}

# Clean up
cleanup() {
    log_info "Cleaning up..."
    make clean
    nix store gc
    log_success "Cleanup completed"
}

# Main function
main() {
    log_info "Starting local CI testing for nix-mox"

    # Pre-flight checks
    check_nix
    check_flake

    # Run CI jobs
    local exit_code=0

    if build_packages; then
        log_success "✅ build_packages job passed"
    else
        log_error "❌ build_packages job failed"
        exit_code=1
    fi

    if run_tests; then
        log_success "✅ test job passed"
    else
        log_error "❌ test job failed"
        exit_code=1
    fi

    if run_checks; then
        log_success "✅ checks passed"
    else
        log_error "❌ checks failed"
        exit_code=1
    fi

    release_dry_run

    # Cleanup
    cleanup

    if [ $exit_code -eq 0 ]; then
        log_success "🎉 All CI jobs passed locally!"
    else
        log_error "💥 Some CI jobs failed locally"
    fi

    exit $exit_code
}

# Handle script arguments
case "${1:-}" in
    "build")
        check_nix
        check_flake
        build_packages
        ;;
    "test")
        check_nix
        check_flake
        run_tests
        ;;
    "checks")
        check_nix
        check_flake
        run_checks
        ;;
    "clean")
        cleanup
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [build|test|checks|clean|help]"
        echo ""
        echo "Commands:"
        echo "  build   - Run only the build_packages job"
        echo "  test    - Run only the test job"
        echo "  checks  - Run only the checks"
        echo "  clean   - Clean up artifacts"
        echo "  help    - Show this help message"
        echo ""
        echo "If no command is provided, runs all CI jobs"
        ;;
    *)
        main
        ;;
esac
