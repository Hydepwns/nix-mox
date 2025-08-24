#!/usr/bin/env nu

# Import unified libraries
use ../../../lib/unified-checks.nu
use ../../../lib/unified-logging.nu *
use ../../../lib/unified-error-handling.nu *


# Hardware detection module for display tests
# Handles GPU detection, display environment detection, and hardware analysis

use ../../lib/test-utils.nu *
use ../../lib/test-common.nu *

export def detect_gpu_hardware [] {
    print $"($env.CYAN)🔍 Detecting GPU hardware... ($env.NC)"
    try {
        let lspci_output = (safe_command "lspci | grep -i vga")
        if ($lspci_output | str contains "NVIDIA") {
            {
                type: "nvidia"
                name: ($lspci_output | str replace ".*: " "")
                driver: "nvidia"
                vulkan: true
                risk_level: "medium"
                detected: true
            }
        } else if ($lspci_output | str contains "AMD") {
            {
                type: "amd"
                name: ($lspci_output | str replace ".*: " "")
                driver: "amdgpu"
                vulkan: true
                risk_level: "low"
                detected: true
            }
        } else if ($lspci_output | str contains "Intel") {
            {
                type: "intel"
                name: ($lspci_output | str replace ".*: " "")
                driver: "i915"
                vulkan: false
                risk_level: "low"
                detected: true
            }
        } else {
            {
                type: "unknown"
                name: "Unknown GPU"
                driver: "auto"
                vulkan: false
                risk_level: "high"
                detected: false
            }
        }
    } catch { |err|
        {
            type: "error"
            name: "Detection failed"
            driver: "unknown"
            vulkan: false
            risk_level: "high"
            detected: false
            error: $err
        }
    }
}

export def detect_display_environment [] {
    print $"($env.CYAN)🖥️  Detecting display environment... ($env.NC)"

    # Detect X11/Wayland
    let display_info = try {
        let x11_check = (safe_command "echo $env.DISPLAY")
        if ($x11_check | str length) > 0 {
            {
                display_server: "X11"
                display_var: $x11_check
            }
        } else {
            let wayland_check = (safe_command "echo $env.WAYLAND_DISPLAY")
            if ($wayland_check | str length) > 0 {
                {
                    display_server: "Wayland"
                    display_var: $wayland_check
                }
            } else {
                {
                    display_server: "Unknown"
                    display_var: ""
                }
            }
        }
    } catch {
        {
            display_server: "Error"
            display_var: ""
            error: $env.LAST_ERROR
        }
    }

    # Detect desktop environment
    let desktop_info = try {
        let desktop = (safe_command "echo $env.XDG_CURRENT_DESKTOP")
        let session = (safe_command "echo $env.XDG_SESSION_TYPE")
        
        {
            desktop: $desktop
            session_type: $session
        }
    } catch {
        {
            desktop: "Unknown"
            session_type: "Unknown"
        }
    }

    # Combine display and desktop info
    $display_info | merge $desktop_info
}

export def analyze_hardware_compatibility [gpu_info: record, display_info: record] {
    print $"($env.CYAN)🔧 Analyzing hardware compatibility... ($env.NC)"
    
    let compatibility = {
        gpu_supported: false
        display_supported: false
        driver_available: false
        vulkan_supported: false
        issues: []
        recommendations: []
    }

    # Check GPU compatibility
    if $gpu_info.detected {
        $compatibility | upsert gpu_supported true
    } else {
        $compatibility | upsert issues ($compatibility.issues | append "GPU not detected")
        $compatibility | upsert recommendations ($compatibility.recommendations | append "Check hardware connections and drivers")
    }

    # Check display server compatibility
    if ($display_info.display_server == "X11" or $display_info.display_server == "Wayland") {
        $compatibility | upsert display_supported true
    } else {
        $compatibility | upsert issues ($compatibility.issues | append "Display server not detected")
        $compatibility | upsert recommendations ($compatibility.recommendations | append "Install and configure display server")
    }

    # Check driver availability
    let driver_check = try {
        safe_command $"modinfo ($gpu_info.driver) 2>/dev/null | head -n 1"
        true
    } catch {
        false
    }
    
    if $driver_check {
        $compatibility | upsert driver_available true
    } else {
        $compatibility | upsert issues ($compatibility.issues | append $"Driver ($gpu_info.driver) not available")
        $compatibility | upsert recommendations ($compatibility.recommendations | append $"Install ($gpu_info.driver) driver")
    }

    # Check Vulkan support
    if $gpu_info.vulkan {
        $compatibility | upsert vulkan_supported true
    } else {
        $compatibility | upsert recommendations ($compatibility.recommendations | append "Vulkan support not available")
    }

    $compatibility
} 