#!/usr/bin/env bash

echo "🎮 Installing missing gaming validation tools..."

# Check if we're in a NixOS environment
if command -v nix-env >/dev/null 2>&1; then
    echo "📦 Installing via nix-env..."
    
    # Install missing tools
    nix-env -iA nixpkgs.pciutils      # lspci
    nix-env -iA nixpkgs.mesa-demos    # glxinfo
    nix-env -iA nixpkgs.pulseaudio    # pactl
    nix-env -iA nixpkgs.ufw           # ufw
    
    echo "✅ Tools installed via nix-env"
    
elif command -v nix >/dev/null 2>&1; then
    echo "📦 Installing via nix profile..."
    
    # Install missing tools
    nix profile install nixpkgs#pciutils
    nix profile install nixpkgs#mesa-demos
    nix profile install nixpkgs#pulseaudio
    nix profile install nixpkgs#ufw
    
    echo "✅ Tools installed via nix profile"
    
else
    echo "❌ Nix not found. Please install the following packages manually:"
    echo "  - pciutils (for lspci)"
    echo "  - mesa-demos (for glxinfo)"
    echo "  - pulseaudio (for pactl)"
    echo "  - ufw (for firewall)"
    echo ""
    echo "Or add them to your NixOS configuration.nix:"
    echo "environment.systemPackages = with pkgs; ["
    echo "  pciutils"
    echo "  mesa-demos"
    echo "  pulseaudio"
    echo "  ufw"
    echo "];"
fi

echo ""
echo "🔍 Re-running tool check..."
./scripts/check-gaming-tools.sh 