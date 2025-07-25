#!/usr/bin/env bash

# nix-mox Zed Extension Build Script
# Builds and installs the Zed extension for nix-mox

set -e

echo "🔧 Building nix-mox Zed extension..."

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust/Cargo not found. Please install Rust first."
    echo "   Visit: https://rustup.rs/"
    exit 1
fi

# Check if Zed is installed
if ! command -v zed &> /dev/null; then
    echo "❌ Zed not found. Please install Zed first."
    echo "   Visit: https://zed.dev/"
    exit 1
fi

# Build the extension
echo "📦 Building extension..."
cargo build --release

# Create extension package
echo "📦 Creating extension package..."
EXTENSION_NAME="nix-mox-zed"
EXTENSION_VERSION="1.0.0"
PACKAGE_DIR="target/release/${EXTENSION_NAME}-${EXTENSION_VERSION}"

# Create package directory
mkdir -p "$PACKAGE_DIR"

# Copy extension files
cp extension.json "$PACKAGE_DIR/"
cp -r src "$PACKAGE_DIR/"
cp Cargo.toml "$PACKAGE_DIR/"
cp README.md "$PACKAGE_DIR/"

# Copy built binary
cp target/release/nix-mox-zed "$PACKAGE_DIR/"

echo "✅ Extension built successfully!"
echo "📁 Package location: $PACKAGE_DIR"

# Optional: Install extension
if [[ "$1" == "--install" ]]; then
    echo "📦 Installing extension..."

    # Get Zed extensions directory
    ZED_EXTENSIONS_DIR="$HOME/.config/zed/extensions"

    if [[ ! -d "$ZED_EXTENSIONS_DIR" ]]; then
        mkdir -p "$ZED_EXTENSIONS_DIR"
    fi

    # Copy extension to Zed extensions directory
    cp -r "$PACKAGE_DIR" "$ZED_EXTENSIONS_DIR/"

    echo "✅ Extension installed successfully!"
    echo "🔄 Please restart Zed to load the extension."
fi

echo ""
echo "🎉 Build complete!"
echo ""
echo "To install the extension, run:"
echo "  ./build.sh --install"
echo ""
echo "To use the extension:"
echo "  1. Restart Zed"
echo "  2. Open a .nu file"
echo "  3. Use Cmd/Ctrl+Shift+P to access nix-mox commands"
