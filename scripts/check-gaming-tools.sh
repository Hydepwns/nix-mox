#!/usr/bin/env bash

REQUIRED_TOOLS=(
  nproc free lspci glxinfo vulkaninfo pactl pipewire-pulse gamemoded mangohud
  steam lutris wine ufw ss awk grep cut uniq sort head cat
)

echo "Checking for required tools..."
MISSING=0
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "❌ $tool is missing"
    MISSING=1
  else
    echo "✅ $tool found"
  fi
done

if [ "$MISSING" -eq 0 ]; then
  echo "All required tools are installed!"
else
  echo "Some tools are missing. Please install the missing tools for full validation."
fi 