# install.nu - Install nix-mox scripts
# This script is intended for non-NixOS systems. For NixOS, use the flake.
# Usage: sudo nu install.nu [--dry-run] [--windows-dir /path/to/win/dir] [--help]
#
# - Installs all .nu scripts to /usr/local/bin
# - Creates an install manifest at /etc/nix-mox/install_manifest.txt
# - Is idempotent and safe to re-run
use logging.nu *
use ../../lib/logging.nu *
use ../../lib/validators.nu *

# --- Global Variables ---
const INSTALL_DIR = "/usr/local/bin"
const MANIFEST_DIR = "/etc/nix-mox"
const MANIFEST_FILE = $MANIFEST_DIR + "/install_manifest.txt"

def update-state [field: string, value: any] {
    $env.STATE = ($env.STATE | upsert $field $value)
}

def main [] {
    $env.STATE = {
        dry_run: false
        windows_dir: ""
        created_files: []
    }

    # --- Argument Parsing ---
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => {
                $env.STATE = ($env.STATE | upsert dry_run true)
            }
            "--windows-dir" => {
                let idx = ($args | find $arg | get 0)
                let new_dir = ($args | get ($idx + 1))
                if not ($new_dir | str starts-with "/") {
                    error "Windows path must be absolute." "install"
                    exit 1
                }
                $env.STATE = ($env.STATE | upsert windows_dir $new_dir)
            }
            "--help" | "-h" => {
                usage
            }
            _ => {
                error $"Unknown option: ($arg)" "install"
                usage
            }
        }
    }

    # Check if running as root
    if (whoami | str trim) != 'root' {
        error "This script must be run as root." "install"
        exit 1
    }

    if $env.STATE.dry_run {
        dry_run "Dry-run mode enabled. No files will be changed." "install"
    } else {
        # Prepare manifest directory and file
        mkdir $MANIFEST_DIR
        $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $MANIFEST_DIR))
        touch $MANIFEST_FILE
        $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $MANIFEST_FILE))
    }

    # 1. Install Linux scripts
    info $"Installing Linux scripts to ($INSTALL_DIR)..." "install"
    for script in (ls *.nu) {
        if ($script.name == "_common.nu" or $script.name == "install.nu" or $script.name == "uninstall.nu") {
            continue
        }
        let dest_path = $INSTALL_DIR + "/" + ($script.name | str replace ".nu" "")

        if $env.STATE.dry_run {
            dry_run $"Would install '($script.name)' to '($dest_path)'" "install"
        } else {
            info $"Installing '($script.name)' to '($dest_path)'..." "install"
            cp $script.name $dest_path
            chmod 755 $dest_path
            $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $dest_path))
        }
    }

    # 2. Copy Windows scripts if requested
    if $env.STATE.windows_dir != "" {
        info $"Copying Windows scripts to ($env.STATE.windows_dir)..." "install"
        let win_scripts_src = "../windows"

        if $env.STATE.dry_run {
            dry_run $"Would create directory '($env.STATE.windows_dir)' and copy files into it." "install"
        } else {
            mkdir $env.STATE.windows_dir
            $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $env.STATE.windows_dir))

            for f in (ls ($win_scripts_src + "/*")) {
                let dest_file = $env.STATE.windows_dir + "/" + ($f.name | path basename)
                info $"Copying '($f.name)' to '($dest_file)'..." "install"
                cp $f.name $dest_file
                $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $dest_file))
            }
        }
    }

    if $env.STATE.dry_run {
        dry_run "Dry run complete." "install"
    } else {
        success "Installation complete." "install"
        info $"An install manifest has been created at: ($MANIFEST_FILE)" "install"
        info "Use uninstall.nu to remove all installed files." "install"
    }

    return $env.STATE
}

def cleanup [created_files: list] {
    # This function is called on error to roll back this run's changes.
    if ($created_files | length) == 0 {
        return
    }

    warn "An error occurred. Rolling back changes made during this installation run..." "install"

    # Iterate in reverse to remove files before directories
    for item in ($created_files | reverse) {
        if ($item | path exists) {
            if ($item | path type) == "file" {
                warn $"Removing file: ($item)" "install"
                rm $item
            } else if ($item | path type) == "dir" {
                # Only remove dir if it's empty
                try {
                    rmdir $item
                    warn $"Removing directory: ($item)" "install"
                } catch {
                    warn $"Directory not empty, skipping removal: ($item)" "install"
                }
            }
        }
    }

    warn "Rollback complete." "install"
}

def add_to_manifest [file_path: string, dry_run: bool] {
    # Adds a file or directory path to the manifest for the uninstaller.
    if $dry_run {
        return
    }

    # Ensure file exists before adding
    if not ((open $MANIFEST_FILE | lines | where $it == $file_path | length | into int) > 0) {
        $file_path | save --append $MANIFEST_FILE
    }
}

# --- Execution ---
try {
    main
} catch {
    cleanup $env.STATE.created_files
    exit 1
}
