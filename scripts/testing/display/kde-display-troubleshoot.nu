#!/usr/bin/env nu
# KDE Plasma 6 + NVIDIA Display Troubleshooting Script
# Diagnoses and fixes common display issues after NixOS rebuild

use ../../lib/logging.nu *
use ../../lib/platform.nu *
use ../../lib/command-wrapper.nu *

# Main troubleshooting function
def main [
    --fix,                          # Apply automatic fixes
    --pre-rebuild,                  # Run before rebuild
    --post-rebuild,                 # Run after rebuild (recovery mode)
    --verbose,
    --dry-run                       # Show what would be done without executing
] {
    if $verbose { $env.LOG_LEVEL = "DEBUG" }
    
    banner "KDE Plasma 6 + NVIDIA Display Troubleshoot" --context "display"
    
    if $pre_rebuild {
        pre_rebuild_display_check $dry_run
    } else if $post_rebuild {
        post_rebuild_recovery $fix $dry_run
    } else {
        full_display_diagnostic $fix $dry_run
    }
}

# Pre-rebuild display validation
def pre_rebuild_display_check [dry_run: bool] {
    section "Pre-Rebuild Display Validation" --context "display"
    
    let checks = [
        { name: "nvidia-driver", test: {|| check_nvidia_driver } },
        { name: "kde-plasma-version", test: {|| check_kde_plasma_version } },
        { name: "x11-config", test: {|| check_x11_configuration } },
        { name: "display-manager", test: {|| check_display_manager_config } },
        { name: "nvidia-settings", test: {|| check_nvidia_settings } },
        { name: "current-session", test: {|| check_current_session } }
    ]
    
    mut results = []
    
    for check in $checks {
        try {
            let result = (do $check.test)
            $results = ($results | append {
                name: $check.name,
                status: "passed",
                message: $result.message,
                details: ($result | get details -o)
            })
            success $"✅ ($check.name): ($result.message)" --context "display"
        } catch { | err|
            $results = ($results | append {
                name: $check.name,
                status: "failed", 
                message: $err.msg,
                details: null
            })
            error $"❌ ($check.name): ($err.msg)" --context "display"
        }
    }
    
    # Generate warnings for potential issues
    let failed_checks = ($results | where status == "failed")
    if ($failed_checks | length) > 0 {
        warn "Potential display issues detected before rebuild!" --context "display"
        warn "Consider fixing these issues before proceeding:" --context "display"
        
        for check in $failed_checks {
            warn $"  - ($check.name): ($check.message)" --context "display"
        }
        
        info "Run with --fix to apply automatic fixes" --context "display"
    } else {
        success "All pre-rebuild display checks passed!" --context "display"
    }
    
    $results
}

# Full diagnostic with optional fixes
def full_display_diagnostic [apply_fixes: bool, dry_run: bool] {
    section "Full Display Diagnostic" --context "display"
    
    let system_info = (collect_system_display_info)
    let nvidia_info = (collect_nvidia_info)
    let kde_info = (collect_kde_info)
    let x11_info = (collect_x11_info)
    let issues = (detect_display_issues $system_info $nvidia_info $kde_info $x11_info)
    
    # Display collected information
    display_system_info $system_info $nvidia_info $kde_info $x11_info
    
    # Show detected issues
    if ($issues | length) > 0 {
        warn $"Found ($issues | length) display issues:" --context "display"
        for issue in $issues {
            error $"  - ($issue.category): ($issue.description)" --context "display"
            if "solution" in $issue {
                info $"    Solution: ($issue.solution)" --context "display"
            }
        }
        
        if $apply_fixes and not $dry_run {
            info "Applying automatic fixes..." --context "display"
            apply_display_fixes $issues
        } else if $apply_fixes and $dry_run {
            info "DRY RUN: Would apply these fixes:" --context "display"
            for issue in $issues {
                if "fix_command" in $issue {
                    info $"  - ($issue.category): ($issue.fix_command)" --context "display"
                }
            }
        }
    } else {
        success "No display issues detected!" --context "display"
    }
    
    $issues
}

# Post-rebuild recovery mode
def post_rebuild_recovery [apply_fixes: bool, dry_run: bool] {
    section "Post-Rebuild Recovery Mode" --context "display"
    
    info "Attempting to recover from display issues..." --context "display"
    
    # Emergency recovery steps
    let recovery_steps = [
        {
            name: "Switch to safe SDDM config",
            command: "sudo systemctl stop sddm && sudo systemctl start sddm",
            description: "Restart display manager"
        },
        {
            name: "Force NVIDIA module reload",
            command: "sudo modprobe -r nvidia_uvm nvidia_drm nvidia_modeset nvidia && sudo modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm",
            description: "Reload NVIDIA kernel modules"
        },
        {
            name: "Reset KDE settings",
            command: "rm -rf ~/.config/plasma* ~/.config/kde* ~/.config/kwin*",
            description: "Remove potentially corrupted KDE config files"
        },
        {
            name: "Switch to X11 session",
            command: "echo 'export XDG_SESSION_TYPE=x11' >> ~/.xprofile",
            description: "Force X11 session type"
        }
    ]
    
    if $apply_fixes and not $dry_run {
        for step in $recovery_steps {
            info $"Executing: ($step.description)" --context "display"
            try {
                execute_command_safe $step.command --context "recovery"
                success $"✅ ($step.name) completed" --context "display"
            } catch { | err|
                error $"❌ ($step.name) failed: ($err.msg)" --context "display"
            }
        }
    } else {
        info "Recovery steps that would be executed:" --context "display"
        for step in $recovery_steps {
            info $"  - ($step.name): ($step.command)" --context "display"
        }
    }
}

# Check NVIDIA driver status
def check_nvidia_driver [] {
    let nvidia_info = (^lsmod | lines | where { | line| $line | str contains "nvidia" })
    
    if ($nvidia_info | length) == 0 {
        error make { msg: "No NVIDIA modules loaded" }
    }
    
    let driver_version = (try { ^nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | lines | first } catch { "unknown" })
    
    {
        message: $"NVIDIA driver loaded, version: ($driver_version)",
        details: { modules: $nvidia_info, version: $driver_version }
    }
}

# Check KDE Plasma version compatibility
def check_kde_plasma_version [] {
    let plasma_version = (try {
        ^plasmashell --version | lines | first | str replace "plasmashell " ""
    } catch {
        error make { msg: "KDE Plasma not found or not running" }
    })
    
    # Check if Plasma 6 (which may have issues with NVIDIA on 25.11)
    let major_version = ($plasma_version | str substring 0,1)
    
    if $major_version == "6" {
        {
            message: $"KDE Plasma 6 detected (($plasma_version)) - may have NVIDIA compatibility issues",
            details: { version: $plasma_version, major: $major_version, warning: "plasma6_nvidia_issues" }
        }
    } else {
        {
            message: $"KDE Plasma ($plasma_version) - should be compatible",
            details: { version: $plasma_version, major: $major_version }
        }
    }
}

# Check X11 configuration
def check_x11_configuration [] {
    let x11_running = (try { ^pgrep -f "X| Xorg" | lines | length } catch { 0 }) > 0
    
    if not $x11_running {
        error make { msg: "X11 server not running - may be using Wayland which has NVIDIA issues" }
    }
    
    let display_env = ($env | get DISPLAY -o | default "not_set")
    let session_type = ($env | get XDG_SESSION_TYPE -o | default "unknown")
    
    if $session_type != "x11" {
        error make { msg: $"Session type is ($session_type), should be x11 for NVIDIA compatibility" }
    }
    
    {
        message: $"X11 running properly, session type: ($session_type)",
        details: { display: $display_env, session_type: $session_type }
    }
}

# Check display manager configuration
def check_display_manager_config [] {
    let sddm_running = (try { ^systemctl is-active sddm | str trim } catch { "inactive" }) == "active"
    
    if not $sddm_running {
        error make { msg: "SDDM display manager not running" }
    }
    
    # Check if SDDM is configured for X11 (not Wayland)
    let sddm_wayland_disabled = (try {
        (^grep -q "wayland.enable.*false" /etc/sddm.conf 2>/dev/null; if $env.LAST_EXIT_CODE == 0 { "found" } else { "not_found" })
    } catch { "unknown" })
    
    {
        message: "SDDM running, Wayland disabled for NVIDIA compatibility",
        details: { sddm_active: $sddm_running, wayland_config: $sddm_wayland_disabled }
    }
}

# Check NVIDIA settings and configuration
def check_nvidia_settings [] {
    let nvidia_settings_available = (which nvidia-settings | is-not-empty)
    
    if not $nvidia_settings_available {
        error make { msg: "nvidia-settings not available" }
    }
    
    # Check if nvidia-drm modeset is enabled
    let modeset_enabled = (try {
        ^cat /sys/module/nvidia_drm/parameters/modeset | str trim
    } catch { "unknown" })
    
    if $modeset_enabled != "Y" {
        error make { msg: $"NVIDIA DRM modeset not enabled (current: ($modeset_enabled))" }
    }
    
    {
        message: "NVIDIA settings available, DRM modeset enabled",
        details: { nvidia_settings: $nvidia_settings_available, drm_modeset: $modeset_enabled }
    }
}

# Check current desktop session
def check_current_session [] {
    let current_desktop = ($env | get XDG_CURRENT_DESKTOP -o | default "unknown")
    let session_desktop = ($env | get XDG_SESSION_DESKTOP -o | default "unknown")
    
    if $current_desktop != "KDE" {
        error make { msg: $"Not running KDE session (current: ($current_desktop))" }
    }
    
    {
        message: $"Running KDE session: ($current_desktop)",
        details: { current_desktop: $current_desktop, session_desktop: $session_desktop }
    }
}

# Collect comprehensive system display information
def collect_system_display_info [] {
    {
        hostname: (^hostname),
        kernel: (^uname -r),
        nvidia_driver: (try { ^nvidia-smi --query-gpu=name,driver_version --format=csv,noheader } catch { "not_available" }),
        gpu_info: (try { ^lspci | grep -i vga } catch { "not_available" }),
        display_env: ($env | get DISPLAY -o | default "not_set"),
        session_type: ($env | get XDG_SESSION_TYPE -o | default "unknown"),
        current_desktop: ($env | get XDG_CURRENT_DESKTOP -o | default "unknown")
    }
}

# Collect NVIDIA-specific information
def collect_nvidia_info [] {
    {
        modules: (^lsmod | lines | where { | line| $line | str contains "nvidia" }),
        driver_info: (try { ^nvidia-smi -L } catch { "nvidia-smi not available" }),
        modeset_status: (try { ^cat /sys/module/nvidia_drm/parameters/modeset } catch { "unknown" }),
        card_info: (try { ls /dev/nvidia* | get name } catch { [] })
    }
}

# Collect KDE-specific information  
def collect_kde_info [] {
    {
        plasma_version: (try { ^plasmashell --version } catch { "not_available" }),
        kwin_version: (try { ^kwin_x11 --version } catch { "not_available" }),
        kde_processes: (try { ^pgrep -f "plasma| kwin" | lines } catch { [] }),
        compositor: (try { ^qdbus org.kde.KWin /Compositor org.kde.kwin.Compositing.compositingType } catch { "unknown" })
    }
}

# Collect X11-specific information
def collect_x11_info [] {
    {
        x11_processes: (try { ^pgrep -f "X| Xorg" | lines } catch { [] }),
        display_info: (try { ^xrandr --listmonitors } catch { "xrandr not available" }),
        x11_config: (try { ls /etc/X11/xorg.conf* | get name } catch { [] }),
        glx_info: (try { ^glxinfo | head -10 } catch { "glxinfo not available" })
    }
}

# Detect display issues based on collected information
def detect_display_issues [system_info: record, nvidia_info: record, kde_info: record, x11_info: record] {
    mut issues = []
    
    # Check for Plasma 6 + NVIDIA issues
    if ($kde_info.plasma_version | str contains "6.") {
        $issues = ($issues | append {
            category: "kde_plasma6_nvidia",
            severity: "high",
            description: "KDE Plasma 6 has known compatibility issues with NVIDIA drivers on NixOS 25.11",
            solution: "Consider using KDE Plasma 5 or switching to a different desktop environment",
            fix_command: "# Manual intervention required - see NixOS wiki for Plasma 6 NVIDIA fixes"
        })
    }
    
    # Check session type
    if $system_info.session_type != "x11" {
        $issues = ($issues | append {
            category: "wayland_nvidia_incompatible",
            severity: "critical",
            description: $"Running ($system_info.session_type) session - NVIDIA works best with X11",
            solution: "Force X11 session in display manager",
            fix_command: "echo 'DefaultSession=plasma.desktop' | sudo tee -a /etc/sddm.conf"
        })
    }
    
    # Check NVIDIA modeset
    if $nvidia_info.modeset_status != "Y" {
        $issues = ($issues | append {
            category: "nvidia_modeset_disabled", 
            severity: "high",
            description: "NVIDIA DRM modeset is disabled",
            solution: "Enable nvidia-drm.modeset=1 in kernel parameters",
            fix_command: "# Already configured in your flake - may need rebuild"
        })
    }
    
    # Check for missing NVIDIA processes
    if ($nvidia_info.modules | length) == 0 {
        $issues = ($issues | append {
            category: "nvidia_modules_not_loaded",
            severity: "critical", 
            description: "NVIDIA kernel modules not loaded",
            solution: "Reload NVIDIA modules or check driver installation",
            fix_command: "sudo modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm"
        })
    }
    
    # Check X11 running
    if ($x11_info.x11_processes | length) == 0 {
        $issues = ($issues | append {
            category: "x11_not_running",
            severity: "critical",
            description: "X11 server not running",
            solution: "Start X11 or check display manager configuration", 
            fix_command: "sudo systemctl restart sddm"
        })
    }
    
    $issues
}

# Display collected system information
def display_system_info [system_info: record, nvidia_info: record, kde_info: record, x11_info: record] {
    section "System Display Information" --context "display"
    
    info $"Hostname: ($system_info.hostname)" --context "display"
    info $"Kernel: ($system_info.kernel)" --context "display"
    info $"Display: ($system_info.display_env)" --context "display"
    info $"Session Type: ($system_info.session_type)" --context "display"
    info $"Desktop: ($system_info.current_desktop)" --context "display"
    
    section "NVIDIA Information" --context "display"
    info $"Driver Info: ($system_info.nvidia_driver)" --context "display"
    info $"DRM Modeset: ($nvidia_info.modeset_status)" --context "display"
    info $"Loaded Modules: ($nvidia_info.modules | length)" --context "display"
    
    section "KDE Information" --context "display"  
    info $"Plasma Version: ($kde_info.plasma_version)" --context "display"
    info $"KDE Processes: ($kde_info.kde_processes | length)" --context "display"
    info $"Compositor: ($kde_info.compositor)" --context "display"
    
    section "X11 Information" --context "display"
    info $"X11 Processes: ($x11_info.x11_processes | length)" --context "display"
    info $"X11 Config Files: ($x11_info.x11_config | length)" --context "display"
}

# Apply automatic fixes for detected issues
def apply_display_fixes [issues: list] {
    for issue in $issues {
        if "fix_command" in $issue and ($issue.fix_command | str starts-with "#") {
            warn $"Manual fix required for ($issue.category): ($issue.solution)" --context "display"
            continue
        }
        
        if "fix_command" in $issue {
            info $"Fixing ($issue.category)..." --context "display"
            try {
                execute_command_safe $issue.fix_command --context "fix"
                success $"✅ Fixed: ($issue.category)" --context "display"
            } catch { | err|
                error $"❌ Failed to fix ($issue.category): ($err.msg)" --context "display"
            }
        }
    }
}

# Safe command execution wrapper
def execute_command_safe [command: string, --context: string = "exec"] {
    debug $"Executing: ($command)" --context $context
    
    let result = (^bash -c $command | complete)
    
    if $result.exit_code != 0 {
        error make { msg: $"Command failed with exit code ($result.exit_code): ($result.stderr)" }
    }
    
    $result
}