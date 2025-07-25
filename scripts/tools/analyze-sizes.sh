#!/usr/bin/env bash

# nix-mox Size Analysis Script
# ============================
# Analyzes the size of all packages, devshells, and templates
# Provides detailed reporting and performance tradeoffs

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

log_header() {
  echo -e "${PURPLE}$1${NC}"
}

# Convert bytes to human readable format
format_size() {
  local bytes=$1
  if [ "$bytes" -gt 1073741824 ]; then
    echo "$(echo "scale=2; $bytes/1073741824" | bc) GB"
  elif [ "$bytes" -gt 1048576 ]; then
    echo "$(echo "scale=2; $bytes/1048576" | bc) MB"
  elif [ "$bytes" -gt 1024 ]; then
    echo "$(echo "scale=2; $bytes/1024" | bc) KB"
  else
    echo "${bytes} B"
  fi
}

# Get system architecture
get_system() {
  case "$(uname -m)" in
    x86_64)
      if [[ $OSTYPE == "darwin"* ]]; then
        echo "x86_64-darwin"
      else
        echo "x86_64-linux"
      fi
      ;;
    aarch64 | arm64)
      if [[ $OSTYPE == "darwin"* ]]; then
        echo "aarch64-darwin"
      else
        echo "aarch64-linux"
      fi
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Analyze packages
analyze_packages() {
  local system=$1
  local packages=("proxmox-update" "vzdump-backup" "zfs-snapshot" "nixos-flake-update" "install" "uninstall")

  log_header "📦 Package Analysis"
  echo "------------------"
  echo ""

  local total_size=0

  for package in "${packages[@]}"; do
    log_info "Analyzing package: $package..."

    # Check if package exists for this system
    if ! nix flake show .#"$package" > /dev/null 2>&1; then
      log_warning "Package $package not available for $system"
      continue
    fi

    # Build package and measure time
    local start_time
    start_time=$(date +%s)
    nix build .#"$package" --no-link > /dev/null 2>&1
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Get closure size
    local closure_size
    closure_size=$(nix path-info --closure-size .#"$package" 2> /dev/null | awk '{print $1}' | head -1)
    if [ -z "$closure_size" ] || [ "$closure_size" = "0" ]; then
      closure_size=0
    fi

    # Get individual package size
    local package_size
    package_size=$(nix path-info --size .#"$package" 2> /dev/null | awk '{print $1}' | head -1)
    if [ -z "$package_size" ] || [ "$package_size" = "0" ]; then
      package_size=0
    fi

    local deps_size
    deps_size=$((closure_size - package_size))
    local size_formatted
    size_formatted=$(format_size "$closure_size")
    local pkg_size_formatted
    pkg_size_formatted=$(format_size "$package_size")
    local deps_size_formatted
    deps_size_formatted=$(format_size "$deps_size")

    printf "  %-20s | %8s total | %8s package | %8s deps | %ds\n" \
      "$package" "$size_formatted" "$pkg_size_formatted" "$deps_size_formatted" "$duration"

    total_size=$((total_size + closure_size))
  done

  echo ""
  local total_formatted
  total_formatted=$(format_size "$total_size")
  echo "Total package size: $total_formatted"
  echo ""

  # Return total size for summary
  echo $total_size
}

# Analyze devshells
analyze_devshells() {
  local system=$1
  local shells=("default" "development" "testing" "services" "monitoring" "gaming" "zfs" "macos")

  log_header "💻 Development Shell Analysis"
  echo "----------------------------"
  echo ""

  local total_size=0
  local unavailable_shells=()

  for shell in "${shells[@]}"; do
    log_info "Analyzing devshell: $shell..."

    # Check if shell exists for this system
    if ! nix flake show .#devShells."$shell" > /dev/null 2>&1; then
      unavailable_shells+=("$shell")
      continue
    fi

    # Build shell and measure time
    local start_time
    start_time=$(date +%s)
    nix build .#devShells."$shell" --no-link > /dev/null 2>&1
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Get closure size
    local closure_size
    closure_size=$(nix path-info --closure-size .#devShells."$shell" 2> /dev/null | awk '{print $1}' | head -1)
    if [ -z "$closure_size" ] || [ "$closure_size" = "0" ]; then
      closure_size=0
    fi

    local size_formatted
    size_formatted=$(format_size "$closure_size")
    printf "  %-15s | %8s | %ds\n" "$shell" "$size_formatted" "$duration"

    total_size=$((total_size + closure_size))
  done

  echo ""
  if [ ${#unavailable_shells[@]} -gt 0 ]; then
    echo "Unavailable shells for this system:"
    for shell in "${unavailable_shells[@]}"; do
      echo "  - $shell"
    done
    echo ""
  fi

  local total_formatted
  total_formatted=$(format_size "$total_size")
  echo "Total devshell size: $total_formatted"
  echo ""

  # Return total size for summary
  echo $total_size
}

# Analyze templates
analyze_templates() {
  local system=$1

  log_header "🏗️ Template Analysis"
  echo "-------------------"
  echo ""

  # Get available NixOS configurations
  local configs
  configs=$(nix flake show .#nixosConfigurations 2> /dev/null | grep "nixosConfigurations\." | sed 's/nixosConfigurations\.//' | tr -d ' ')

  if [ -z "$configs" ]; then
    echo "No NixOS configurations found for this system."
    echo ""
    echo "0"
    return
  fi

  local total_size=0

  for config in $configs; do
    log_info "Analyzing template: $config..."

    # Build configuration and measure time
    local start_time
    start_time=$(date +%s)
    nix build .#nixosConfigurations."$config".config.system.build.toplevel --no-link > /dev/null 2>&1
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Get closure size
    local closure_size
    closure_size=$(nix path-info --closure-size .#nixosConfigurations."$config".config.system.build.toplevel 2> /dev/null | awk '{print $1}' | head -1)
    if [ -z "$closure_size" ] || [ "$closure_size" = "0" ]; then
      closure_size=0
    fi

    local size_formatted
    size_formatted=$(format_size "$closure_size")
    printf "  %-20s | %8s | %ds\n" "$config" "$size_formatted" "$duration"

    total_size=$((total_size + closure_size))
  done

  echo ""
  local total_formatted
  total_formatted=$(format_size "$total_size")
  echo "Total template size: $total_formatted"
  echo ""

  # Return total size for summary
  echo $total_size
}

# Generate summary
generate_summary() {
  local package_size=${1:-0}
  local devshell_size=${2:-0}
  local template_size=${3:-0}
  local system=$4

  local grand_total=$((package_size + devshell_size + template_size))

  log_header "📈 Summary Report"
  echo "----------------"
  echo ""

  local total_formatted
  total_formatted=$(format_size "$grand_total")
  local packages_formatted
  packages_formatted=$(format_size "$package_size")
  local devshells_formatted
  devshells_formatted=$(format_size "$devshell_size")
  local templates_formatted
  templates_formatted=$(format_size "$template_size")

  echo "📊 Total Repository Size: $total_formatted"
  echo "   📦 Packages: $packages_formatted"
  echo "   💻 DevShells: $devshells_formatted"
  echo "   🏗️ Templates: $templates_formatted"
  echo ""

  # Performance recommendations
  log_header "💡 Performance Recommendations"
  echo "----------------------------"
  echo ""

  local total_mb=$((grand_total / 1024 / 1024))

  if [ "$total_mb" -gt 5000 ]; then
    log_warning "Large repository size detected (>5GB)"
    echo "   - Consider using smaller templates for development"
    echo "   - Use specific devshells instead of the full development shell"
    echo "   - Clean up unused packages with 'nix store gc'"
  elif [ "$total_mb" -gt 2000 ]; then
    log_success "Moderate repository size (2-5GB)"
    echo "   - Good balance between features and size"
    echo "   - Consider the gaming shell only if needed (largest devshell)"
  else
    log_success "Compact repository size (<2GB)"
    echo "   - Excellent for quick development and CI/CD"
    echo "   - Good choice for resource-constrained environments"
  fi

  echo ""
  echo "💡 Optimization Tips:"
  echo "   - Use 'nix develop .#specific-shell' instead of the default shell"
  echo "   - Build only needed packages: 'nix build .#package-name'"
  echo "   - Use 'nix store gc' regularly to clean up unused derivations"
  echo "   - Consider using smaller templates for testing and development"
  echo ""

  # Save report
  local report_file
  report_file="nix-mox-size-analysis-${system}-$(date +%Y%m%d-%H%M%S).json"
  cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system": "$system",
    "totals": {
        "packages": $package_size,
        "devshells": $devshell_size,
        "templates": $template_size,
        "grand_total": $grand_total
    },
    "formatted": {
        "packages": "$packages_formatted",
        "devshells": "$devshells_formatted",
        "templates": "$templates_formatted",
        "grand_total": "$total_formatted"
    }
}
EOF

  log_success "Detailed report saved to: $report_file"
}

# Show help
show_help() {
  echo "nix-mox Size Analysis Script"
  echo ""
  echo "Usage:"
  echo "  analyze-sizes.sh [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message"
  echo ""
  echo "What it does:"
  echo "  • Analyzes package sizes and build times"
  echo "  • Analyzes development shell sizes"
  echo "  • Analyzes template sizes"
  echo "  • Generates performance recommendations"
  echo "  • Saves detailed report to JSON file"
  echo ""
  echo "Examples:"
  echo "  ./scripts/tools/analyze-sizes.sh     # Run analysis"
  echo "  ./scripts/tools/analyze-sizes.sh -h  # Show help"
}

# Main function
main() {
  # Check for help flag
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
  fi

  echo "🔍 nix-mox Size Analysis"
  echo "========================"
  echo ""

  # Check if we're in the right directory
  if [ ! -f "flake.nix" ]; then
    log_error "Must be run from nix-mox root directory"
    exit 1
  fi

  # Get system architecture
  local system
  system=$(get_system)
  log_info "Analyzing for system: $system"
  echo ""

  # Analyze all components, capture only the last line (numeric value)
  local package_size
  package_size=$(analyze_packages "$system" | tail -n1)
  local devshell_size
  devshell_size=$(analyze_devshells "$system" | tail -n1)
  local template_size
  template_size=$(analyze_templates "$system" | tail -n1)

  # Generate summary
  generate_summary "$package_size" "$devshell_size" "$template_size" "$system"
}

# Run main function
main "$@"
