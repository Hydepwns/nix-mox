# nix-mox Windows Uninstallation Script
# This script handles the uninstallation of nix-mox on Windows/WSL

Write-Host "🗑️  Uninstalling nix-mox from Windows/WSL..."

# Check if running in WSL
if ($env:WSL_DISTRO_NAME) {
    Write-Host "Detected WSL environment: $($env:WSL_DISTRO_NAME)"
    Write-Host "📦 Removing nix-mox from Nix profile..."
    bash -c "nix profile remove github:your-username/nix-mox"
    Write-Host "🧹 Cleaning up remaining files..."
    bash -c "rm -rf ~/.config/nix-mox ~/.local/share/nix-mox"
    Write-Host "✅ nix-mox uninstallation complete!"
    exit 0
}

# Native Windows (PowerShell)
Write-Host "⚠️  Native Windows uninstall is experimental."
Write-Host "Please use WSL for best results."

Write-Host "📦 Removing nix-mox from Nix profile..."
nix profile remove github:your-username/nix-mox
Write-Host "🧹 Cleaning up remaining files..."
Remove-Item -Recurse -Force "$env:USERPROFILE\.config\nix-mox" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.local\share\nix-mox" -ErrorAction SilentlyContinue
Write-Host "✅ nix-mox uninstallation complete!"
