#!/usr/bin/env bash

# Setup script for Hydepwns dotfiles integration
# This script helps integrate the Hydepwns dotfiles with nix-mox

set -e

echo "🔧 Setting up Hydepwns dotfiles integration..."

# Check if chezmoi is available
if command -v chezmoi &> /dev/null; then
    echo "✅ Chezmoi found, setting up dotfiles..."

    # Initialize chezmoi with Hydepwns dotfiles
    chezmoi init --apply https://github.com/Hydepwns/dotfiles

    echo "✅ Dotfiles initialized successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "  1. Review the dotfiles configuration"
    echo "  2. Customize as needed"
    echo "  3. The dotfiles will be automatically loaded in your shell"
    echo ""
else
    echo "⚠️  Chezmoi not found. Installing..."

    # Try to install chezmoi
    if command -v nix &> /dev/null; then
        echo "📦 Installing chezmoi via nix..."
        nix profile install nixpkgs#chezmoi
        echo "✅ Chezmoi installed! Please run this script again."
    else
        echo "❌ Could not install chezmoi automatically."
        echo "   Please install chezmoi manually and run this script again."
        echo "   Visit: https://www.chezmoi.io/install/"
    fi
fi

# Create symlinks for common tools
echo "🔗 Setting up tool symlinks..."

HOME_DIR="$HOME"
CONFIG_DIR="$HOME_DIR/.config"

# Ensure config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

# Set up Zed configuration
ZED_CONFIG="$CONFIG_DIR/zed"
if [ ! -d "$ZED_CONFIG" ]; then
    mkdir -p "$ZED_CONFIG"
    echo "✅ Created Zed config directory"
fi

# Set up Kitty configuration
KITTY_CONFIG="$CONFIG_DIR/kitty"
if [ ! -d "$KITTY_CONFIG" ]; then
    mkdir -p "$KITTY_CONFIG"
    echo "✅ Created Kitty config directory"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Summary:"
echo "  • Zed editor configured"
echo "  • Kitty terminal configured"
echo "  • Hydepwns dotfiles integration ready"
echo "  • Blender available"
echo "  • Devenv and direnv configured"
echo ""
echo "🚀 You can now:"
echo "  • Use 'zed' to open the editor"
echo "  • Use 'kitty' to open the terminal"
echo "  • Use 'blender' to open 3D software"
echo "  • Use 'direnv allow' to load the development environment"
echo ""
