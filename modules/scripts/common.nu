# Common utilities for nix-mox
# This module provides shared functionality used across the project

# --- Logging Functions ---
export def log_info [message: string] {
    print $"[INFO] ($message)"
}

export def log_error [message: string] {
    print $"[ERROR] ($message)"
}

export def log_warn [message: string] {
    print $"[WARN] ($message)"
}

export def log_debug [message: string] {
    if ($env.DEBUG? | default false) {
        print $"[DEBUG] ($message)"
    }
}

# --- Platform Detection ---
export def detect_platform [] {
    let os = (sys host | get name)
    match $os {
        "Linux" | "NixOS" => { "linux" }
        "Darwin" => { "darwin" }
        _ => { error make { msg: $"Unsupported platform: ($os)" } }
    }
}

# --- Error Handling ---
export def handle_error [error: any] {
    log_error $"Error: ($error)"
    exit 1
}

# --- File Operations ---
export def ensure_dir [path: string] {
    if not ($path | path exists) {
        mkdir $path
        log_info $"Created directory: ($path)"
    }
}

export def ensure_file [path: string] {
    if not ($path | path exists) {
        touch $path
        log_info $"Created file: ($path)"
    }
}

# --- Configuration ---
export def load_config [config_path: string] {
    if ($config_path | path exists) {
        open $config_path
    } else {
        error make { msg: $"Configuration file not found: ($config_path)" }
    }
}

# --- Validation ---
export def validate_required [value: any, name: string] {
    if ($value | is-empty) {
        error make { msg: $"Required value missing: ($name)" }
    }
}

# --- Command Execution ---
export def run_command [command: string, args: list] {
    try {
        ^$command $args
    } catch {
        handle_error $env.LAST_ERROR
    }
}

# --- Environment Setup ---
export def setup_env [] {
    $env.DEBUG = ($env.DEBUG? | default false)
    $env.PLATFORM = detect_platform
}

# --- OS Info ---
export def print_os_info [] {
    let platform = ($env.PLATFORM? | default (detect_platform))
    if $platform == "linux" {
        let os_release = (if ("/etc/os-release" | path exists) { open "/etc/os-release" | lines | parse "{k}={v}" | reduce -f {} {|row, acc| $acc | upsert $row.k $row.v } } else { {} })
        let distro = ($os_release.NAME? | default "Unknown Linux")
        let version = ($os_release.VERSION? | default "Unknown Version")
        let kernel = (do { ^uname -r } | complete | get stdout | str trim)
        print $"[INFO] Distro: ($distro) ($version) | Kernel: ($kernel)"
    } else if $platform == "darwin" {
        let version = (sw_vers -productVersion | str trim)
        print $"[INFO] macOS Version: ($version)"
    } else if $platform == "windows" {
        let version = (wmic os get Caption,CSDVersion /value | lines | str join " ")
        print $"[INFO] Windows Version: ($version)"
    } else {
        print $"[INFO] Platform: ($platform)"
    }
}

# --- Version Management ---
export def get_version [] {
    let version_file = "version/version.nu"
    if ($version_file | path exists) {
        open $version_file | get version
    } else {
        "0.0.0"
    }
}

# --- Utility Functions ---
export def is_root [] {
    if $env.PLATFORM == "linux" {
        (id -u) == 0
    } else if $env.PLATFORM == "darwin" {
        (id -u) == 0
    } else {
        false
    }
}

export def require_root [] {
    if not (is_root) {
        error make { msg: "This operation requires root privileges" }
    }
}

# --- Path Management ---
export def get_project_root [] {
    let git_root = (do { git rev-parse --show-toplevel } | complete | get stdout | str trim)
    if ($git_root | is-empty) {
        $env.PWD
    } else {
        $git_root
    }
}

# --- Test Helpers ---
export def setup_test_env [] {
    let temp_dir = (mktemp -d)
    $env.TEST_TEMP_DIR = $temp_dir
    log_info $"Created test environment at: ($temp_dir)"
}

export def cleanup_test_env [] {
    if ($env.TEST_TEMP_DIR? | default false) {
        rm -rf $env.TEST_TEMP_DIR
        log_info $"Cleaned up test environment at: ($env.TEST_TEMP_DIR)"
    }
}
