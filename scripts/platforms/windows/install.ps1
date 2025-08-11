# nix-mox Windows Installation Script
# This script handles the installation of nix-mox on Windows/WSL

Write-Host "🪟 Installing nix-mox on Windows/WSL..."

# Check if running in WSL
if ($env:WSL_DISTRO_NAME) {
    Write-Host "Detected WSL environment: $($env:WSL_DISTRO_NAME)"
    # Check if Nix is installed
    if (-not (Get-Command nix -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Nix is not installed. Installing Nix..."
        bash -c "curl -L https://nixos.org/nix/install | sh"
    } else {
        Write-Host "✅ Nix is already installed"
    }
    Write-Host "📦 Installing nix-mox..."
    bash -c "nix profile install github:your-username/nix-mox"
    Write-Host "✅ nix-mox installation complete!"
    exit 0
}

# Native Windows (PowerShell)
Write-Host "⚠️  Native Windows install is experimental."
Write-Host "Please use WSL for best results."

# Check for Nix (native)
if (-not (Get-Command nix -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Nix is not installed. Please install Nix manually from https://nixos.org/download.html#windows"
    exit 1
}

Write-Host "📦 Installing nix-mox..."
nix profile install github:your-username/nix-mox
Write-Host "✅ nix-mox installation complete!"
