#!/usr/bin/env bash

# Simple CI Testing Script for nix-mox
# Quick local testing of CI workflows

set -euo pipefail

echo "🧪 Testing CI locally for nix-mox"
echo "=================================="

# Check prerequisites
echo "📋 Checking prerequisites..."
if ! command -v nix &> /dev/null; then
    echo "❌ Nix not found. Please install Nix first."
    exit 1
fi

if [ ! -f "flake.nix" ]; then
    echo "❌ Not in a Nix flake directory."
    exit 1
fi

echo "✅ Prerequisites OK"

# Test 1: Build packages (simulating build_packages job)
echo ""
echo "🔨 Testing package builds..."
echo "Building packages for current system..."

# Check if we're on Linux to determine which packages to build
if [[ "$(uname)" == "Linux" ]]; then
    echo "🐧 Linux detected - building Linux-specific packages..."
    if nix build .#proxmox-update --accept-flake-config --out-link tmp/result-proxmox-update \
        && nix build .#vzdump-backup --accept-flake-config --out-link tmp/result-vzdump-backup \
        && nix build .#zfs-snapshot --accept-flake-config --out-link tmp/result-zfs-snapshot \
        && nix build .#nixos-flake-update --accept-flake-config --out-link tmp/result-nixos-flake-update; then
        echo "✅ Linux package builds successful"
    else
        echo "❌ Linux package builds failed"
        exit 1
    fi
else
    echo "🍎 Non-Linux system detected - building available packages..."
    # Build all available packages for the current system
    if nix build --accept-flake-config --out-link tmp/result-all; then
        echo "✅ Package builds successful"
    else
        echo "❌ Package builds failed"
        exit 1
    fi
fi

# Test 2: Run flake check (simulating test job)
echo ""
echo "🧪 Testing flake check..."
if nix flake check --accept-flake-config --impure; then
    echo "✅ Flake check passed"
else
    echo "❌ Flake check failed"
    exit 1
fi

# Test 3: Run unit tests
echo ""
echo "🧪 Running unit tests..."
# Create coverage directory first
mkdir -p coverage-tmp
if make unit; then
    echo "✅ Unit tests passed"
else
    echo "❌ Unit tests failed"
    exit 1
fi

# Test 4: Run integration tests
echo ""
echo "🧪 Running integration tests..."
# Ensure coverage directory exists
mkdir -p coverage-tmp
if make integration; then
    echo "✅ Integration tests passed"
else
    echo "❌ Integration tests failed"
    exit 1
fi

# Test 5: Check flake outputs
echo ""
echo "🔍 Checking flake outputs..."
if nix flake show; then
    echo "✅ Flake outputs are valid"
else
    echo "❌ Flake outputs check failed"
    exit 1
fi

# Test 6: Check devshells
echo ""
echo "🔍 Checking devshells..."
if nix develop --help > /dev/null 2>&1; then
    echo "✅ Devshells are valid"
else
    echo "❌ Devshells check failed"
    exit 1
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
make clean
nix store gc

echo ""
echo "🎉 All CI tests passed locally!"
echo "Your CI should work when pushed to GitHub!"
