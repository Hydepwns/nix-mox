# install.nu - Install nix-mox scripts
# This script is intended for non-NixOS systems. For NixOS, use the flake.
# Usage: sudo nu install.nu [--dry-run] [--windows-dir /path/to/win/dir] [--help]
#
# - Installs all .nu scripts to /usr/local/bin
# - Creates an install manifest at /etc/nix-mox/install_manifest.txt
# - Is idempotent and safe to re-run

use ../lib/common.nu *

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
            "--dry-run" => { update-state "dry_run" true }
            "--windows-dir" => {
                let idx = ($args | find $arg | get 0)
                let new_dir = ($args | get ($idx + 1))
                if not ($new_dir | str starts-with "/") {
                    log_error "Windows path must be absolute."
                    exit 1
                }
                update-state "windows_dir" $new_dir
            }
            "--help" | "-h" => { usage }
            _ => {
                log_error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    check_root

    if $env.STATE.dry_run {
        log_dryrun "Dry-run mode enabled. No files will be changed."
    } else {
        # Prepare manifest directory and file
        mkdir $MANIFEST_DIR
        update-state "created_files" ($env.STATE.created_files | append $MANIFEST_DIR)
        touch $MANIFEST_FILE
        update-state "created_files" ($env.STATE.created_files | append $MANIFEST_FILE)
    }

    # 1. Install Linux scripts
    log_info $"Installing Linux scripts to ($INSTALL_DIR)..."
    for script in (ls *.nu) {
        if ($script.name == "_common.nu" or $script.name == "install.nu" or $script.name == "uninstall.nu") {
            continue
        }

        let dest_path = $INSTALL_DIR + "/" + ($script.name | str replace ".nu" "")
        if $env.STATE.dry_run {
            log_dryrun $"Would install '($script.name)' to '($dest_path)'"
        } else {
            log_info $"Installing '($script.name)' to '($dest_path)'..."
            cp $script.name $dest_path
            chmod 755 $dest_path
            update-state "created_files" ($env.STATE.created_files | append $dest_path)
            add_to_manifest $dest_path $env.STATE.dry_run
        }
    }

    # 2. Copy Windows scripts if requested
    if $env.STATE.windows_dir != "" {
        log_info $"Copying Windows scripts to ($env.STATE.windows_dir)..."
        let win_scripts_src = "../windows"

        if $env.STATE.dry_run {
            log_dryrun $"Would create directory '($env.STATE.windows_dir)' and copy files into it."
        } else {
            mkdir $env.STATE.windows_dir
            update-state "created_files" ($env.STATE.created_files | append $env.STATE.windows_dir)
            add_to_manifest $env.STATE.windows_dir $env.STATE.dry_run

            for f in (ls ($win_scripts_src + "/*")) {
                let dest_file = $env.STATE.windows_dir + "/" + ($f.name | path basename)
                log_info $"Copying '($f.name)' to '($dest_file)'..."
                cp $f.name $dest_file
                update-state "created_files" ($env.STATE.created_files | append $dest_file)
                add_to_manifest $dest_file $env.STATE.dry_run
            }
        }
    }

    if $env.STATE.dry_run {
        log_dryrun "Dry run complete."
    } else {
        log_success "Installation complete."
        log_info $"An install manifest has been created at: ($MANIFEST_FILE)"
        log_info "Use uninstall.nu to remove all installed files."
    }

    return $env.STATE
}

def cleanup [created_files: list] {
    # This function is called on error to roll back this run's changes.
    if ($created_files | length) == 0 {
        return
    }

    log_warn "An error occurred. Rolling back changes made during this installation run..."
    # Iterate in reverse to remove files before directories
    for item in ($created_files | reverse) {
        if ($item | path exists) {
            if ($item | path type) == "file" {
                log_warn $"Removing file: ($item)"
                rm $item
            } else if ($item | path type) == "dir" {
                # Only remove dir if it's empty
                try {
                    rmdir $item
                    log_warn $"Removing directory: ($item)"
                } catch {
                    log_warn $"Directory not empty, skipping removal: ($item)"
                }
            }
        }
    }
    log_warn "Rollback complete."
}

def add_to_manifest [file_path: string, dry_run: bool] {
    # Adds a file or directory path to the manifest for the uninstaller.
    if $dry_run { return }
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
