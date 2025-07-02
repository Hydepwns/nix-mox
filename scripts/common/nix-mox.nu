#!/usr/bin/env nu

# Main script for nix-mox
use ../lib/common.nu *

# Fallback error if not defined
if (not (scope commands | where name == 'error' | is-not-empty)) {
    export def error [message: string] {
        print $"Error: ($message)"
    }
}

# --- Command Line Arguments ---
def get_flag_value [args: list, flag: string, default: any] {
    let idx = ($args | enumerate | where item == $flag | get index.0? )
    if ($idx | is-not-empty) and ($args | length) > ($idx + 1) {
        $args | get ($idx + 1)
    } else {
        $default
    }
}

def parse_args [args: list] {
    let help = ($args | any { |it| $it == "--help" or $it == "-h" })
    let dry_run = ($args | any { |it| $it == "--dry-run" })
    let debug = ($args | any { |it| $it == "--debug" })
    let platform = (get_flag_value $args "--platform" "auto")
    let script = (get_flag_value $args "--script" "")
    let log_file = (get_flag_value $args "--log" "")

    {
        help: $help
        dry_run: $dry_run
        debug: $debug
        platform: $platform
        script: $script
        log_file: $log_file
    }
}

# --- Help Message ---
def show_help [] {
    print "nix-mox - Proxmox templates + NixOS workstation + Windows gaming automation"
    print ""
    print "Usage:"
    print "  nix-mox [options]"
    print ""
    print "Options:"
    print "  -h, --help           Show this help message"
    print "  --dry-run           Show what would be done without making changes"
    print "  --debug             Enable debug output"
    print "  --platform <os>     Specify platform (auto, linux, darwin)"
    print "  --script <name>     Run specific script (install, update, zfs-snapshot, setup-interactive)"
    print "  --log <file>        Log output to file"
    print ""
    print "Examples:"
    print "  nix-mox --help"
    print "  nix-mox --platform auto --dry-run"
    print "  nix-mox --script install --debug"
    print "  nix-mox --script zfs-snapshot --log output.log"
    print "  nix-mox --script setup-interactive"
}

# --- Error Handling ---
def handle_error [error_msg: string, exit_code: int = 1] {
    error $error_msg
    if ($env.LOG_FILE? | is-not-empty) {
        error "Check the log file for more details: ($env.LOG_FILE)"
    }
    exit $exit_code
}

def check_command [cmd: string] {
    if (which $cmd | is-empty) {
        handle_error $"Required command not found: ($cmd)"
    }
}

def check_file [file: string, error_msg: string] {
    if not ($file | path exists) {
        handle_error $"($error_msg): ($file)"
    }
}

def check_directory [dir: string, error_msg: string] {
    if not ($dir | path exists) {
        handle_error $"($error_msg): ($dir)"
    }
}

def check_permissions [path: string, required: string] {
    let perms = (ls -l $path | get mode)
    if not ($perms | str contains $required) {
        handle_error $"Insufficient permissions on ($path). Required: ($required), Got: ($perms)"
    }
}

# --- Script Execution ---
def run_script [script: string, dry_run: bool] {
    # Validate script name
    if ($script | is-empty) {
        handle_error "No script specified"
    }

    # Check if script is supported
    let supported_scripts = ["install", "update", "zfs-snapshot", "setup-interactive"]
    if not ($supported_scripts | any { |s| $s == $script }) {
        handle_error $"Unsupported script: ($script). Supported scripts: ($supported_scripts | str join ', ')"
    }

    match $script {
        "setup-interactive" => {
            if $dry_run {
                info "Would execute interactive setup script"
            } else {
                info "Running interactive setup script..."

                let setup_script = "scripts/linux/setup-interactive.nu"
                check_file $setup_script "Setup script not found"
                check_permissions $setup_script "x"

                try {
                    nu $setup_script
                    info "Interactive setup completed successfully"
                } catch { |err|
                    handle_error $"Interactive setup failed: ($err)"
                }
            }
        }
        "install" => {
            if $dry_run {
                info "Would execute install script"
            } else {
                info "Running install script..."

                # Get platform-specific install script
                let platform = detect_platform
                let install_script = match $platform {
                    "linux" => "modules/scripts/linux/install.nu",
                    "darwin" => "modules/scripts/linux/install.nu",
                    "windows" => "modules/scripts/windows/install-steam-rust.nu",
                    _ => {
                        handle_error $"Unsupported platform: ($platform)"
                    }
                }

                # Check if install script exists and is executable
                check_file $install_script "Install script not found"
                check_permissions $install_script "x"

                # Run platform-specific install script
                info $"Running platform-specific install script: ($install_script)"
                try {
                    nu $install_script
                    info "Installation completed successfully"
                } catch { |err|
                    handle_error $"Installation failed: ($err)"
                }
            }
        }
        "update" => {
            if $dry_run {
                info "Would execute update script"
            } else {
                info "Running update script..."

                # Get platform-specific update script
                let platform = detect_platform
                match $platform {
                    "linux" | "darwin" => {
                        # Check required commands
                        check_command "nix-channel"
                        check_command "nix-env"

                        # For Linux/macOS, update Nix packages
                        info "Updating Nix packages..."
                        try {
                            nix-channel --update
                            nix-env -u '*'
                            info "Nix packages updated successfully"
                        } catch { |err|
                            handle_error $"Failed to update Nix packages: ($err)"
                        }
                    }
                    "windows" => {
                        # For Windows, update Steam and Rust
                        let win_update_script = "modules/scripts/windows/install-steam-rust.nu"
                        check_file $win_update_script "Update script not found"
                        check_permissions $win_update_script "x"

                        try {
                            nu $win_update_script
                            info "Steam and Rust updated successfully"
                        } catch { |err|
                            handle_error $"Failed to update Steam and Rust: ($err)"
                        }
                    }
                    _ => {
                        handle_error $"Unsupported platform: ($platform)"
                    }
                }
            }
        }
        "zfs-snapshot" => {
            if $dry_run {
                info "Would execute ZFS snapshot script"
            } else {
                info "Running ZFS snapshot script..."

                # Check if ZFS is available and user has permissions
                check_command "zfs"
                try {
                    zfs list > /dev/null
                } catch {
                    handle_error "ZFS command failed. Please check if you have sufficient permissions."
                }

                # Get list of ZFS pools
                try {
                    let pools = (zfs list -H -o name | lines)
                    if ($pools | length) == 0 {
                        handle_error "No ZFS pools found"
                    }

                    # Create snapshots for each pool
                    let failed_snapshots = ($pools | each { |pool|
                        let timestamp = (date now | format date '%Y%m%d-%H%M%S')
                        let snapshot_name = $"($pool)@($timestamp)"
                        info $"Creating snapshot: ($snapshot_name)"
                        try {
                            zfs snapshot $snapshot_name
                            info $"Created snapshot: ($snapshot_name)"
                            null
                        } catch { |err|
                            error $"Failed to create snapshot ($snapshot_name): ($err)"
                            $snapshot_name
                        }
                    } | where { |it| $it != null })

                    # Report any failed snapshots
                    if ($failed_snapshots | length) > 0 {
                        warn $"Failed to create ($failed_snapshots | length) snapshots:"
                        for snapshot in $failed_snapshots {
                            warn $"  - ($snapshot)"
                        }
                        handle_error "Some snapshots failed to create" 0  # Exit with warning
                    }
                } catch { |err|
                    handle_error $"Failed to list ZFS pools: ($err)"
                }
            }
        }
        _ => {
            handle_error $"Invalid script: ($script)"
        }
    }
}

# --- Logging Functions ---
def log_to_file [message: string, log_file: string] {
    try {
        $message | save --append $log_file
    } catch { |err|
        print $"Failed to write to log file ($log_file): ($err)"
        print $message
    }
}

def setup_file_logging [log_file: string] {
    # Create log directory if it doesn't exist
    let log_dir = ($log_file | path dirname)
    try {
        if not ($log_dir | path exists) {
            mkdir $log_dir
        }
        check_permissions $log_dir "w"

        # Setup file logging
        try {
            # Redirect stdout and stderr to log file
            $env.LOG_FILE = $log_file
            info $"Logging to: ($log_file)"

            # Override logging functions to write to file
            def info [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[INFO] ($timestamp) ($message)" $log_file
            }

            def error [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[ERROR] ($timestamp) ($message)" $log_file
            }

            def log_dryrun [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[DRYRUN] ($timestamp) ($message)" $log_file
            }

            def warn [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[WARN] ($timestamp) ($message)" $log_file
            }
        } catch { |err|
            handle_error $"Failed to setup logging to ($log_file): ($err)"
        }
    } catch { |err|
        handle_error $"Failed to create log directory ($log_dir): ($err)"
    }
}

# --- Main Function ---
def main [args: list] {
    # Early help check
    if ($args | any { |it| $it == "--help" or $it == "-h" }) {
        show_help
        exit 0
    }

    let parsed_args = (parse_args $args)

    # Set debug mode
    if $parsed_args.debug {
        $env.DEBUG = true
    }

    # Only require --script if not showing help
    if ($parsed_args.script | is-empty) {
        handle_error "No script specified. Use --script <name> to run a script."
    }

    # Detect platform and print info only if running a script
    let platform = detect_platform
    info $"Platform: ($platform)"
    print_os_info

    # Setup logging
    if not ($parsed_args.log_file | is-empty) {
        setup_file_logging $parsed_args.log_file
    }

    # Run script
    run_script $parsed_args.script $parsed_args.dry_run
}

# Note: This script is called by the bash wrapper (nix-mox) which handles
# argument passing reliably. The wrapper sets NIXMOX_ARGS as a string of all arguments.

# Read arguments from NIXMOX_ARGS environment variable
let args = (if ($env.NIXMOX_ARGS? | default "") == "" {
    []
} else {
    $env.NIXMOX_ARGS | split row " "
})

# Call main with parsed arguments
main $args
