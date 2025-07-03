#!/usr/bin/env nu
# Display Testing Utilities for nix-mox
# Helper functions for display configuration testing and validation

export-env {
    use ../lib/test-utils.nu *
    use ../lib/test-common.nu *
}

# --- Safe Command Execution ---
def safe_command [command: string] {
    try {
        do { nu -c $command }
    } catch {
        ""
    }
}

def safe_command_with_timeout [command: string, timeout: int = 30] {
    try {
        do { timeout $timeout nu -c $command }
    } catch {
        ""
    }
}

# --- Configuration Validation ---
def validate_nix_syntax [config_path: string] {
    try {
        let result = (safe_command $"nix-instantiate --parse ($config_path)")
        if ($result | str length) > 0 {
            { valid: true, error: "" }
        } else {
            { valid: false, error: "Empty result from nix-instantiate" }
        }
    } catch { |err|
        { valid: false, error: $err }
    }
}

def validate_nixos_config [config_path: string] {
    try {
        let result = (safe_command $"nixos-rebuild dry-activate --flake .#nixos")
        { valid: true, error: "" }
    } catch { |err|
        { valid: false, error: $err }
    }
}

def check_configuration_changes [old_config: string, new_config: string] {
    try {
        let diff_result = (safe_command $"diff ($old_config) ($new_config)")
        if ($diff_result | str length) > 0 {
            {
                has_changes: true
                changes: $diff_result
                change_count: ($diff_result | lines | length)
            }
        } else {
            {
                has_changes: false
                changes: ""
                change_count: 0
            }
        }
    } catch { |err|
        {
            has_changes: false
            changes: ""
            change_count: 0
            error: $err
        }
    }
}

# --- Backup Management ---
def create_backup [source_path: string, backup_dir: string, prefix: string = "backup"] {
    try {
        # Ensure backup directory exists
        if not ($backup_dir | path exists) {
            mkdir $backup_dir
        }

        let timestamp = (date now | format date "%Y%m%d_%H%M%S")
        let filename = ($source_path | path basename)
        let backup_path = $"($backup_dir)/($prefix)_($filename)_($timestamp)"

        # Copy file
        cp $source_path $backup_path

        {
            success: true
            backup_path: $backup_path
            timestamp: $timestamp
            original_path: $source_path
        }
    } catch { |err|
        {
            success: false
            error: $err
            original_path: $source_path
        }
    }
}

def restore_backup [backup_path: string, target_path: string] {
    try {
        cp $backup_path $target_path
        {
            success: true
            restored_path: $target_path
            backup_path: $backup_path
        }
    } catch { |err|
        {
            success: false
            error: $err
            backup_path: $backup_path
        }
    }
}

def list_backups [backup_dir: string] {
    try {
        if ($backup_dir | path exists) {
            ls $backup_dir | where name =~ r'backup_.*\.nix'
        } else {
            []
        }
    } catch {
        []
    }
}

# --- Hardware Detection Utilities ---
def get_gpu_info [] {
    try {
        let lspci_output = (safe_command "lspci | grep -i vga")
        if ($lspci_output | str length) > 0 {
            $lspci_output
        } else {
            "No GPU detected"
        }
    } catch {
        "GPU detection failed"
    }
}

def get_driver_info [] {
    mut driver_info = {}

    # NVIDIA
    try {
        let nvidia_info = (safe_command "nvidia-smi --version")
        if ($nvidia_info | str length) > 0 {
            $driver_info = ($driver_info | upsert nvidia $nvidia_info)
        }
    } catch {}

    # AMD
    try {
        let amd_info = (safe_command "lspci | grep -i amd")
        if ($amd_info | str length) > 0 {
            $driver_info = ($driver_info | upsert amd $amd_info)
        }
    } catch {}

    # Intel
    try {
        let intel_info = (safe_command "lspci | grep -i intel")
        if ($intel_info | str length) > 0 {
            $driver_info = ($driver_info | upsert intel $intel_info)
        }
    } catch {}

    $driver_info
}

def get_display_info [] {
    mut display_info = {}

    # X11
    try {
        let x11_display = (safe_command "echo $DISPLAY")
        if ($x11_display | str length) > 0 {
            $display_info = ($display_info | upsert x11 $x11_display)
        }
    } catch {}

    # Wayland
    try {
        let wayland_display = (safe_command "echo $WAYLAND_DISPLAY")
        if ($wayland_display | str length) > 0 {
            $display_info = ($display_info | upsert wayland $wayland_display)
        }
    } catch {}

    # Desktop environment
    try {
        let desktop = (safe_command "echo $XDG_CURRENT_DESKTOP")
        if ($desktop | str length) > 0 {
            $display_info = ($display_info | upsert desktop $desktop)
        }
    } catch {}

    $display_info
}

# --- Graphics Testing Utilities ---
def test_opengl [] {
    try {
        let opengl_version = (safe_command "glxinfo | grep 'OpenGL version'")
        if ($opengl_version | str length) > 0 {
            {
                available: true
                version: $opengl_version
                error: ""
            }
        } else {
            {
                available: false
                version: ""
                error: "OpenGL not available"
            }
        }
    } catch { |err|
        {
            available: false
            version: ""
            error: $err
        }
    }
}

def test_vulkan [] {
    try {
        let vulkan_info = (safe_command "vulkaninfo | grep 'GPU' | head -n 1")
        if ($vulkan_info | str length) > 0 {
            {
                available: true
                gpu: $vulkan_info
                error: ""
            }
        } else {
            {
                available: false
                gpu: ""
                error: "Vulkan not available"
            }
        }
    } catch { |err|
        {
            available: false
            gpu: ""
            error: $err
        }
    }
}

def test_graphics_performance [] {
    try {
        let glmark_score = (safe_command_with_timeout "glmark2 --fullscreen --duration 5" 60)
        if ($glmark_score | str length) > 0 {
            {
                available: true
                score: $glmark_score
                error: ""
            }
        } else {
            {
                available: false
                score: ""
                error: "glmark2 not available or failed"
            }
        }
    } catch { |err|
        {
            available: false
            score: ""
            error: $err
        }
    }
}

# --- System Health Checks ---
def check_system_health [] {
    # Check disk space
    let disk_usage = try {
        let disk_result = (safe_command "df / | tail -n 1 | awk '{print $5}' | sed 's/%//'")
        $disk_result | into int
    } catch {
        -1
    }

    # Check memory usage
    let memory_usage = try {
        let memory_result = (safe_command "free | grep Mem | awk '{printf \"%.0f\", $3/$2 * 100.0}'")
        $memory_result | into int
    } catch {
        -1
    }

    # Check CPU load
    let cpu_load = try {
        let cpu_result = (safe_command "uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'")
        $cpu_result | into float
    } catch {
        -1.0
    }

    # Check network connectivity
    let network_available = try {
        let network_test = (safe_command "ping -c 1 8.8.8.8")
        ( ($network_test | str length) > 0 )
    } catch {
        false
    }

    {
        disk_usage: $disk_usage
        memory_usage: $memory_usage
        cpu_load: $cpu_load
        network_available: $network_available
    }
}

def check_display_services [] {
    # Check X server
    let x11_running = try {
        let x11_status = (safe_command "systemctl --user status x11-common")
        ($x11_status | str contains "active")
    } catch {
        false
    }

    # Check display manager
    let display_manager_running = try {
        let dm_status = (safe_command "systemctl status sddm")
        ($dm_status | str contains "active")
    } catch {
        false
    }

    # Check audio system
    let audio_running = try {
        let audio_status = (safe_command "systemctl --user status pipewire")
        ($audio_status | str contains "active")
    } catch {
        false
    }

    {
        x11_running: $x11_running
        display_manager_running: $display_manager_running
        audio_running: $audio_running
    }
}

# --- Risk Assessment Utilities ---
def calculate_hardware_risk [gpu_type: string, gpu_detected: bool] {
    mut risk_score = 0
    mut risk_factors = []

    if not $gpu_detected {
        $risk_score = ($risk_score + 3)
        $risk_factors = ($risk_factors | append "GPU not detected")
    }

    if $gpu_type == "nvidia" {
        $risk_score = ($risk_score + 2)
        $risk_factors = ($risk_factors | append "NVIDIA GPU (higher risk)")
    } else if $gpu_type == "unknown" {
        $risk_score = ($risk_score + 2)
        $risk_factors = ($risk_factors | append "Unknown GPU type")
    }

    {
        score: $risk_score
        factors: $risk_factors
        level: (if $risk_score >= 5 { "high" } else if $risk_score >= 3 { "medium" } else { "low" })
    }
}

def calculate_config_risk [config_analysis: record] {
    mut risk_score = 0
    mut risk_factors = []

    if ($config_analysis.has_deprecated_opengl | default false) {
        $risk_score = ($risk_score + 1)
        $risk_factors = ($risk_factors | append "Deprecated OpenGL configuration")
    }

    if ($config_analysis.has_deprecated_pulseaudio | default false) {
        $risk_score = ($risk_score + 1)
        $risk_factors = ($risk_factors | append "Deprecated PulseAudio configuration")
    }

    if not ($config_analysis.has_xserver | default false) {
        $risk_score = ($risk_score + 1)
        $risk_factors = ($risk_factors | append "No X server configuration")
    }

    {
        score: $risk_score
        factors: $risk_factors
        level: (if $risk_score >= 3 { "high" } else if $risk_score >= 1 { "medium" } else { "low" })
    }
}

# --- Export Functions ---
export def validate_config [config_path: string] {
    let syntax_valid = validate_nix_syntax $config_path
    let nixos_valid = validate_nixos_config $config_path

    {
        syntax: $syntax_valid
        nixos: $nixos_valid
        overall_valid: ($syntax_valid.valid and $nixos_valid.valid)
    }
}

export def backup_config [config_path: string, backup_dir: string = "/tmp/nix-mox-backups"] {
    create_backup $config_path $backup_dir "display_config"
}

export def test_graphics [] {
    {
        opengl: (test_opengl)
        vulkan: (test_vulkan)
        performance: (test_graphics_performance)
    }
}

export def get_system_info [] {
    {
        gpu: (get_gpu_info)
        drivers: (get_driver_info)
        display: (get_display_info)
        health: (check_system_health)
        services: (check_display_services)
    }
}

export def assess_risks [gpu_type: string, gpu_detected: bool, config_analysis: record] {
    let hardware_risk = calculate_hardware_risk $gpu_type $gpu_detected
    let config_risk = calculate_config_risk $config_analysis

    {
        hardware: $hardware_risk
        config: $config_risk
        total_score: ($hardware_risk.score + $config_risk.score)
        overall_level: (if ($hardware_risk.score + $config_risk.score) >= 5 { "high" } else if ($hardware_risk.score + $config_risk.score) >= 3 { "medium" } else { "low" })
    }
}
