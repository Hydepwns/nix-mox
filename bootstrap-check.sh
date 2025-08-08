#!/bin/bash

# Bootstrap check script for fresh NixOS installs
# Works with basic shell - no make or nushell required

echo "🔍 nix-mox Bootstrap Requirements Check"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

checks_passed=0
checks_failed=0

check_requirement() {
    local name="$1"
    local command="$2"
    local install_hint="$3"
    
    echo -n "✓ $name: "
    if command -v "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}installed${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}❌ MISSING${NC}"
        echo "  Install with: $install_hint"
        ((checks_failed++))
    fi
}

check_condition() {
    local name="$1"
    local condition="$2"
    local fix_hint="$3"
    
    echo -n "✓ $name: "
    if eval "$condition"; then
        echo -e "${GREEN}yes${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}❌ NO${NC}"
        echo "  Fix with: $fix_hint"
        ((checks_failed++))
    fi
}

# Check basic requirements
check_requirement "Git" "git" "nix-shell -p git"
check_requirement "Nushell" "nu" "nix-shell -p nushell"

# Check system conditions
check_condition "NixOS detected" "test -d /etc/nixos -o -f /etc/NIXOS" "This script requires NixOS"
check_condition "User in wheel group" "groups | grep -q wheel" "Add user to wheel group for sudo access"

# Check disk space
echo -n "✓ Disk space: "
root_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$root_usage" -lt 95 ]; then
    echo -e "${GREEN}${root_usage}% used${NC}"
    ((checks_passed++))
else
    echo -e "${RED}❌ ${root_usage}% used (too high)${NC}"
    echo "  Run: nix-collect-garbage -d"
    ((checks_failed++))
fi

# Check if we're in the right directory
echo -n "✓ nix-mox directory: "
if [ -f "flake.nix" ] && [ -d "scripts" ]; then
    echo -e "${GREEN}detected${NC}"
    ((checks_passed++))
else
    echo -e "${RED}❌ NOT DETECTED${NC}"
    echo "  Make sure you're in the nix-mox directory"
    ((checks_failed++))
fi

echo ""
echo "📊 Results: $checks_passed passed, $checks_failed failed"

if [ $checks_failed -eq 0 ]; then
    echo -e "${GREEN}✅ All bootstrap requirements met!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run safety check:"
    echo "   nix-shell -p nushell --run 'nu scripts/validation/pre-rebuild-safety-check.nu --verbose'"
    echo ""
    echo "2. If safety check passes, run interactive setup:"
    echo "   nix-shell -p nushell --run 'nu scripts/core/interactive-setup.nu'"
    echo ""
    echo "3. Before any nixos-rebuild, always run:"
    echo "   nix-shell -p nushell --run 'nu scripts/validation/pre-rebuild-safety-check.nu'"
    echo ""
    echo "4. Use safe rebuild wrapper instead of direct nixos-rebuild:"
    echo "   nix-shell -p nushell --run 'nu scripts/core/safe-rebuild.nu'"
    exit 0
else
    echo -e "${RED}❌ Bootstrap requirements not met!${NC}"
    echo ""
    echo "Quick fix for missing requirements:"
    if ! command -v git >/dev/null 2>&1; then
        echo "nix-shell -p git"
    fi
    if ! command -v nu >/dev/null 2>&1; then
        echo "nix-shell -p nushell"
    fi
    echo ""
    echo "Or install both at once:"
    echo "nix-shell -p git nushell"
    echo ""
    echo "Then run this script again: ./bootstrap-check.sh"
    exit 1
fi