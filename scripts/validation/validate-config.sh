#!/bin/bash

# NixOS Configuration Validation Script
# Validates configuration before rebuilding

set -e

echo "🔍 Validating NixOS configuration..."

# Check if we're in the right directory
if [[ ! -f "flake.nix" ]]; then
  echo "❌ Not in nix-mox directory. Please run from the project root."
  exit 1
fi

# Check for flake evaluation
echo "🔧 Checking flake evaluation..."
if ! nix --extra-experimental-features "nix-command flakes" flake check --no-build > /dev/null 2>&1; then
  echo "❌ Flake evaluation error"
  nix --extra-experimental-features "nix-command flakes" flake check --no-build 2>&1
  exit 1
else
  echo "✅ Flake evaluates successfully"
fi

# Check for configuration evaluation
echo "🔧 Checking configuration evaluation..."
if ! sudo nixos-rebuild dry-activate --flake .#nixos > /dev/null 2>&1; then
  echo "❌ Configuration evaluation error"
  sudo nixos-rebuild dry-activate --flake .#nixos 2>&1
  exit 1
else
  echo "✅ Configuration evaluates successfully"
fi

# Check for common issues
echo "🔍 Checking for common configuration issues..."

# Check if X11 and Wayland are both enabled
X11_ENABLED=$(grep -c "services.xserver.enable = true" config/nixos/configuration.nix 2> /dev/null || echo "0")
WAYLAND_ENABLED=$(grep -c "wayland = true" config/nixos/configuration.nix 2> /dev/null || echo "0")

if [[ "$X11_ENABLED" -gt 0 && "$WAYLAND_ENABLED" -gt 0 ]]; then
  echo "⚠️  Warning: Both X11 and Wayland appear to be enabled"
fi

# Check for duplicate package managers
NPM_COUNT=$(grep -c "nodePackages.npm" config/nixos/configuration.nix 2> /dev/null || echo "0")
PNPM_COUNT=$(grep -c "nodePackages.pnpm" config/nixos/configuration.nix 2> /dev/null || echo "0")
YARN_COUNT=$(grep -c "nodePackages.yarn" config/nixos/configuration.nix 2> /dev/null || echo "0")

TOTAL_PKG_MANAGERS=$((NPM_COUNT + PNPM_COUNT + YARN_COUNT))
if [[ "$TOTAL_PKG_MANAGERS" -gt 1 ]]; then
  echo "⚠️  Warning: Multiple Node.js package managers detected"
fi

# Check for X11 tools in Wayland setup
X11_TOOLS=$(grep -c "glxinfo\|xrandr\|xset" config/nixos/configuration.nix 2> /dev/null || echo "0")
if [[ "$X11_TOOLS" -gt 0 ]]; then
  echo "⚠️  Warning: X11 tools detected in Wayland configuration"
fi

# Check for missing dependencies
echo "📦 Checking for potential missing dependencies..."

# Check if Niri is properly configured
NIRI_CONFIG=$(grep -c "programs.niri" config/nixos/configuration.nix 2> /dev/null || echo "0")
if [[ "$NIRI_CONFIG" -eq 0 ]]; then
  echo "⚠️  Warning: Niri configuration not found"
fi

# Check for display manager configuration
GDM_CONFIG=$(grep -c "services.displayManager.gdm" config/nixos/configuration.nix 2> /dev/null || echo "0")
if [[ "$GDM_CONFIG" -eq 0 ]]; then
  echo "⚠️  Warning: Display manager configuration not found"
fi

# Check for potential conflicts
echo "🔍 Checking for potential conflicts..."

# Check for duplicate NVIDIA configurations
NVIDIA_CONFIGS=$(grep -c "hardware.nvidia" config/nixos/configuration.nix || echo "0")
if [[ $NVIDIA_CONFIGS -gt 1 ]]; then
  echo "⚠️  Warning: Multiple NVIDIA configurations detected"
fi

# Check for conflicting power management
POWER_MANAGERS=$(grep -c "services\..*\.enable = true" config/nixos/configuration.nix | grep -E "(tlp|auto-cpufreq|thermald)" || echo "0")
if [[ $POWER_MANAGERS -gt 1 ]]; then
  echo "⚠️  Warning: Multiple power management services detected"
fi

echo "✅ Configuration validation complete!"
echo ""
echo "🚀 Ready to rebuild. Run: sudo nixos-rebuild switch --flake .#nixos"
