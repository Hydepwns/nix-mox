#!/usr/bin/env nu

# Main script for nix-mox
use lib/common.nu *

# Fallback log_error if not defined
if (not (scope commands | where name == 'log_error' | is-not-empty)) {
    export def log_error [message: string] {
        print $"Error: ($message)"
    }
}

# --- Command Line Arguments ---
def get_flag_value [args: list, flag: string, default: any] {
    let idx = ($args | find $flag | get 0?)
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
    print "  --script <name>     Run specific script (install, update, zfs-snapshot)"
    print "  --log <file>        Log output to file"
    print ""
    print "Examples:"
    print "  nix-mox --help"
    print "  nix-mox --platform auto --dry-run"
    print "  nix-mox --script install --debug"
    print "  nix-mox --script zfs-snapshot --log output.log"
}

# --- Error Handling ---
def handle_error [error_msg: string, exit_code: int = 1] {
    log_error $error_msg
    if ($env.LOG_FILE? | is-not-empty) {
        log_error "Check the log file for more details: ($env.LOG_FILE)"
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
    let supported_scripts = ["install", "update", "zfs-snapshot"]
    if not ($supported_scripts | any { |s| $s == $script }) {
        handle_error $"Unsupported script: ($script). Supported scripts: ($supported_scripts | str join ', ')"
    }

    match $script {
        "install" => {
            if $dry_run {
                log_info "Would execute install script"
            } else {
                log_info "Running install script..."

                # Get platform-specific install script
                let platform = detect_platform
                let install_script = match $platform {
                    "linux" => "scripts/linux/install.nu",
                    "darwin" => "scripts/linux/install.nu",
                    "windows" => "scripts/windows/install-steam-rust.nu",
                    _ => {
                        handle_error $"Unsupported platform: ($platform)"
                    }
                }

                # Check if install script exists and is executable
                check_file $install_script "Install script not found"
                check_permissions $install_script "x"

                # Run platform-specific install script
                log_info $"Running platform-specific install script: ($install_script)"
                try {
                    nu $install_script
                    log_success "Installation completed successfully"
                } catch {
                    handle_error $"Installation failed: ($env.LAST_ERROR)"
                }
            }
        }
        "update" => {
            if $dry_run {
                log_info "Would execute update script"
            } else {
                log_info "Running update script..."

                # Get platform-specific update script
                let platform = detect_platform
                match $platform {
                    "linux" | "darwin" => {
                        # Check required commands
                        check_command "nix-channel"
                        check_command "nix-env"

                        # For Linux/macOS, update Nix packages
                        log_info "Updating Nix packages..."
                        try {
                            nix-channel --update
                            nix-env -u '*'
                            log_success "Nix packages updated successfully"
                        } catch {
                            handle_error $"Failed to update Nix packages: ($env.LAST_ERROR)"
                        }
                    }
                    "windows" => {
                        # For Windows, update Steam and Rust
                        let win_update_script = "scripts/windows/update-steam-rust.nu"
                        check_file $win_update_script "Update script not found"
                        check_permissions $win_update_script "x"

                        try {
                            nu $win_update_script
                            log_success "Steam and Rust updated successfully"
                        } catch {
                            handle_error $"Failed to update Steam and Rust: ($env.LAST_ERROR)"
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
                log_info "Would execute ZFS snapshot script"
            } else {
                log_info "Running ZFS snapshot script..."

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
                        log_info $"Creating snapshot: ($snapshot_name)"
                        try {
                            zfs snapshot $snapshot_name
                            log_success $"Created snapshot: ($snapshot_name)"
                            null
                        } catch {
                            log_error $"Failed to create snapshot ($snapshot_name): ($env.LAST_ERROR)"
                            $snapshot_name
                        }
                    } | where { |it| $it != null })

                    # Report any failed snapshots
                    if ($failed_snapshots | length) > 0 {
                        log_warn $"Failed to create ($failed_snapshots | length) snapshots:"
                        for snapshot in $failed_snapshots {
                            log_warn $"  - ($snapshot)"
                        }
                        handle_error "Some snapshots failed to create" 0  # Exit with warning
                    }
                } catch {
                    handle_error $"Failed to list ZFS pools: ($env.LAST_ERROR)"
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
    } catch {
        print $"Failed to write to log file ($log_file): ($env.LAST_ERROR)"
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
            log_info $"Logging to: ($log_file)"

            # Override logging functions to write to file
            def log_info [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[INFO] ($timestamp) ($message)" $log_file
            }

            def log_error [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[ERROR] ($timestamp) ($message)" $log_file
            }

            def log_success [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[SUCCESS] ($timestamp) ($message)" $log_file
            }

            def log_dryrun [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[DRYRUN] ($timestamp) ($message)" $log_file
            }

            def log_warn [message: string] {
                let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
                log_to_file $"[WARN] ($timestamp) ($message)" $log_file
            }
        } catch {
            handle_error $"Failed to setup logging to ($log_file): ($env.LAST_ERROR)"
        }
    } catch {
        handle_error $"Failed to create log directory ($log_dir): ($env.LAST_ERROR)"
    }
}

# --- Platform Detection ---
def detect_platform [] {
    let os = (sys | get host.name)
    match $os {
        "Linux" => "linux",
        "Darwin" => "darwin",
        "Windows" => "windows",
        _ => {
            log_error $"Unsupported operating system: ($os)"
            exit 1
        }
    }
}

def get_platform [platform: string] {
    if $platform == "auto" {
        detect_platform
    } else {
        $platform
    }
}

# --- Main Function ---
def main [args: list] {
    try {
        let parsed_args = (parse_args $args)

        # Set debug mode
        if $parsed_args.debug {
            $env.DEBUG = true
        }

        # Show help and exit
        if $parsed_args.help {
            show_help
            exit 0
        }

        # Setup environment
        try {
            setup_env
        } catch {
            handle_error $"Failed to setup environment: ($env.LAST_ERROR)"
        }

        # Detect platform
        let platform = get_platform $parsed_args.platform
        log_info $"Platform: ($platform)"

        # Setup logging
        if not ($parsed_args.log_file | is-empty) {
            setup_file_logging $parsed_args.log_file
        }

        # Run script
        run_script $parsed_args.script $parsed_args.dry_run
    } catch {
        handle_error $"Unexpected error: ($env.LAST_ERROR)"
    }
}

# Run main function with arguments
let args = (if ($in | is-empty) {
    if ($env.ARGS? | is-empty) { [] } else { $env.ARGS }
} else { $in })
main $args
