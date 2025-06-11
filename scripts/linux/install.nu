# install.nu - Install nix-mox scripts
# This script is intended for non-NixOS systems. For NixOS, use the flake.
# Usage: sudo nu install.nu [--dry-run] [--windows-dir /path/to/win/dir] [--help]
#
# - Installs all .nu scripts to /usr/local/bin
# - Creates an install manifest at /etc/nix-mox/install_manifest.txt
# - Is idempotent and safe to re-run

use ../../scripts/_common.nu *

# --- Global Variables ---
const INSTALL_DIR = "/usr/local/bin"
const MANIFEST_DIR = "/etc/nix-mox"
const MANIFEST_FILE = $MANIFEST_DIR + "/install_manifest.txt"
let DRY_RUN = false
let WINDOWS_DIR = ""
# This array tracks files created *by this specific run* for cleanup on failure.
let CREATED_THIS_RUN = []

# --- Functions ---
def cleanup [] {
    # This function is called on error to roll back this run's changes.
    if ($CREATED_THIS_RUN | length) == 0 {
        return
    }

    log_warn "An error occurred. Rolling back changes made during this installation run..."
    # Iterate in reverse to remove files before directories
    for item in ($CREATED_THIS_RUN | reverse) {
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

def add_to_manifest [file_path: string] {
    # Adds a file or directory path to the manifest for the uninstaller.
    if $DRY_RUN { return }
    # Ensure file exists before adding
    if not (open $MANIFEST_FILE | lines | where $it == $file_path | length) > 0 {
        $file_path | save --append $MANIFEST_FILE
    }
}

def main [] {
    # --- Argument Parsing ---
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => { $DRY_RUN = true }
            "--windows-dir" => {
                let idx = ($args | find $arg | get 0)
                $WINDOWS_DIR = $args.($idx + 1)
                if not ($WINDOWS_DIR | str starts-with "/") {
                    log_error "Windows path must be absolute."
                    exit 1
                }
            }
            "--help" | "-h" => { usage }
            _ => {
                log_error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    check_root

    if $DRY_RUN {
        log_dryrun "Dry-run mode enabled. No files will be changed."
    } else {
        # Prepare manifest directory and file
        mkdir $MANIFEST_DIR
        $CREATED_THIS_RUN = ($CREATED_THIS_RUN | append $MANIFEST_DIR)
        touch $MANIFEST_FILE
        $CREATED_THIS_RUN = ($CREATED_THIS_RUN | append $MANIFEST_FILE)
    }

    # 1. Install Linux scripts
    log_info $"Installing Linux scripts to ($INSTALL_DIR)..."
    for script in (ls *.nu) {
        if ($script.name == "_common.nu" or $script.name == "install.nu" or $script.name == "uninstall.nu") {
            continue
        }
        
        let dest_path = $INSTALL_DIR + "/" + ($script.name | str replace ".nu" "")
        if $DRY_RUN {
            log_dryrun $"Would install '($script.name)' to '($dest_path)'"
        } else {
            log_info $"Installing '($script.name)' to '($dest_path)'..."
            cp $script.name $dest_path
            chmod 755 $dest_path
            $CREATED_THIS_RUN = ($CREATED_THIS_RUN | append $dest_path)
            add_to_manifest $dest_path
        }
    }

    # 2. Copy Windows scripts if requested
    if $WINDOWS_DIR != "" {
        log_info $"Copying Windows scripts to ($WINDOWS_DIR)..."
        let win_scripts_src = "../windows"
        
        if $DRY_RUN {
            log_dryrun $"Would create directory '($WINDOWS_DIR)' and copy files into it."
        } else {
            mkdir $WINDOWS_DIR
            $CREATED_THIS_RUN = ($CREATED_THIS_RUN | append $WINDOWS_DIR)
            add_to_manifest $WINDOWS_DIR

            for f in (ls $win_scripts_src/*) {
                let dest_file = $WINDOWS_DIR + "/" + ($f.name | path basename)
                log_info $"Copying '($f.name)' to '($dest_file)'..."
                cp $f.name $dest_file
                $CREATED_THIS_RUN = ($CREATED_THIS_RUN | append $dest_file)
                add_to_manifest $dest_file
            }
        }
    }

    if $DRY_RUN {
        log_dryrun "Dry run complete."
    } else {
        log_success "Installation complete."
        log_info $"An install manifest has been created at: ($MANIFEST_FILE)"
        log_info "Use uninstall.nu to remove all installed files."
    }
}

# --- Execution ---
try {
    main
} catch {
    cleanup
    exit 1
} 