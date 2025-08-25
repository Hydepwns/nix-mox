#!/usr/bin/env nu

# Import unified libraries
use ../../../../../lib/validators.nu
use ../../../../../lib/logging.nu


# Setup Steam EasyAntiCheat Configuration
print "🔧 Setting up Steam EasyAntiCheat Configuration"
print "================================================"

# Step 1: Create Steam EAC environment file
print "📋 Step 1: Creating Steam EAC environment file..."

let steam_env_file = "/home/nixos/.steam/steam/steam_env.sh"

echo '#!/etc/profiles/per-user/nixos/bin/bash
# Steam Environment Variables for EasyAntiCheat

# Proton/Wine
export WINEDEBUG="-all"
export WINEESYNC="1"
export WINEFSYNC="1"
export WINE_LARGE_ADDRESS_AWARE="1"

# Proton GE and Anticheat Support
export PROTON_ENABLE_NVAPI="1"
export PROTON_HIDE_NVIDIA_GPU="0"
export PROTON_NO_ESYNC="0"
export PROTON_NO_FSYNC="0"
export PROTON_EAC_RUNTIME="1"
export PROTON_BATTLEYE_RUNTIME="1"
export PROTON_FORCE_LARGE_ADDRESS_AWARE="1"
export DXVK_HUD="compiler"
export VKD3D_DEBUG="none"
export VKD3D_CONFIG="dxr,dxr11"

# EasyAntiCheat specific
export EAC_RUNTIME_PATH="$HOME/.steam/steam/steamapps/common/Proton EasyAntiCheat Runtime/v2"
if [ -d "$EAC_RUNTIME_PATH/lib64" ]; then
  export LD_LIBRARY_PATH="$EAC_RUNTIME_PATH/lib64:$LD_LIBRARY_PATH"
fi

# NVIDIA
export __GL_THREADED_OPTIMIZATIONS="1"
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP="1"
export __NV_PRIME_RENDER_OFFLOAD="1"
export __VK_LAYER_NV_optimus="NVIDIA_only"
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json"

# Intel CPU optimizations
export INTEL_DEVICE_PLUGIN_XE="1"
export INTEL_OPENCL_ICD="1"
export INTEL_VAAPI_DRIVER="i965"
export LIBVA_DRIVER_NAME="iHD"

# Gaming optimizations
export MANGOHUD="1"
export ENABLE_VKBASALT="1"
export GAMEMODE="1"

# SDL
export SDL_VIDEODRIVER="wayland,x11"

# Intel specific performance
export INTEL_PREFER_SSE4_1="1"

echo "Steam environment variables loaded for EasyAntiCheat"' | save -f $steam_env_file

chmod +x $steam_env_file
print "✅ Steam environment file created: ($steam_env_file)"

# Step 2: Create Steam EAC launcher
print "📋 Step 2: Creating Steam EAC launcher..."

mkdir "/home/nixos/.local/bin"
let steam_wrapper = "/home/nixos/.local/bin/steam-eac"

echo '#!/etc/profiles/per-user/nixos/bin/bash
# Steam launcher with EasyAntiCheat support
source /home/nixos/.steam/steam/steam_env.sh
exec /run/current-system/sw/bin/steam "$@"' | save -f $steam_wrapper

chmod +x $steam_wrapper
print "✅ Steam wrapper created: ($steam_wrapper)"

# Step 3: Create desktop entry
print "📋 Step 3: Creating desktop entry..."

mkdir "/home/nixos/.local/share/applications"
let desktop_entry = "/home/nixos/.local/share/applications/steam-eac.desktop"

echo '[Desktop Entry]
Name=Steam (EasyAntiCheat)
Comment=Steam with EasyAntiCheat support
Exec=/home/nixos/.local/bin/steam-eac
Icon=steam
Terminal=false
Type=Application
Categories=Game;' | save -f $desktop_entry

print "✅ Desktop entry created: ($desktop_entry)"

# Step 4: Verify EAC runtime
print "📋 Step 4: Verifying EAC runtime..."

let eac_path = "/home/nixos/.steam/steam/steamapps/common/Proton EasyAntiCheat Runtime/v2/lib64"
if ($eac_path | path exists) {
    print "✅ EAC Runtime found: ($eac_path)"
    ls $eac_path | grep easyanticheat
} else {
    print "❌ EAC Runtime not found: ($eac_path)"
    print "   Install 'Proton EasyAntiCheat Runtime' from Steam Library"
}

print ""
print "🎮 Steam EasyAntiCheat Setup Complete!"
print "======================================"
print ""
print "✅ Environment variables configured"
print "✅ Steam launcher created: /home/nixos/.local/bin/steam-eac"
print "✅ Desktop entry created: Steam (EasyAntiCheat)"
print ""
print "💡 Usage:"
print "   - Desktop: Look for 'Steam (EasyAntiCheat)' in your app menu"
print "   - Terminal: /home/nixos/.local/bin/steam-eac"
print ""
print "🔧 This setup will persist across NixOS rebuilds!"
print "   The environment variables are already configured in your NixOS config." 