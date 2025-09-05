#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu

# install-steam-rust.nu
# Usage: nu install-steam-rust.nu [--dry-run] [--help]
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --help            Show this help message
#
# Install Steam and prompt for Rust (Facepunch) installation.
#
# Example:
#   nu install-steam-rust.nu --dry-run
#
# Target OS: Windows (NuShell)

let dry_run = ($in | get dry-run | default false)
let help = ($in | get help | default false)
mut errors = []

# Standardized logging function for NuShell
let log = {| level, msg|
    let ts = (date now | format date "%Y-%m-%d %H:%M:%S")
    print $"[$ts] [$level] $msg"
}

let info = {| msg| log "INFO" $msg }
let warn = {| msg| log "WARN" $msg }
let error = {| msg| log "ERROR" $msg }
let success = {| msg| log "SUCCESS" $msg }
let log_dryrun = {| msg| log "DRY RUN" $msg }

if $help {
    info "Usage: nu install-steam-rust.nu [--dry-run] [--help]\n\nOptions:\n  --dry-run         Show what would be done, but make no changes\n  --help            Show this help message\n\nInstall Steam and prompt for Rust (Facepunch) installation.\nTarget OS: Windows (NuShell)\n"
    exit 0
}

# Download Steam installer
let steam_installer = $"($env.TEMP)\\SteamSetup.exe"

if $dry_run {
    log_dryrun "Would download Steam installer to: $steam_installer"
} else {
    info "Downloading Steam installer..."
    let result = (http get "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe" | save $steam_installer | complete)
    if $result.exit_code != 0 {
        error "Failed to download Steam installer."
        $errors = ($errors | append "download")
    } else {
        success "Downloaded Steam installer."
    }
}

# Install Steam silently
if $dry_run {
    log_dryrun "Would run Steam installer silently."
} else {
    info "Installing Steam silently..."
    let result = (run-external $steam_installer "/S" | complete)
    if $result.exit_code != 0 {
        error "Steam installer failed."
        $errors = ($errors | append "install")
    } else {
        success "Steam installed."
    }
}

# Wait for install to finish
if $dry_run {
    log_dryrun "Would wait 30 seconds for install."
} else {
    info "Waiting for install to finish..."
    sleep 30sec
}

# Start Steam to initialize (will prompt for login)
if $dry_run {
    log_dryrun "Would start Steam to initialize."
} else {
    info "Starting Steam to initialize..."
    let result = (run-external "C:\\Program Files (x86)\\Steam\\Steam.exe" | complete)
    if $result.exit_code != 0 {
        error "Failed to start Steam."
        $errors = ($errors | append "start_steam")
    } else {
        success "Steam started."
    }
    sleep 30sec
}

# Kill Steam process (if running)
if $dry_run {
    log_dryrun "Would kill Steam process if running."
} else {
    info "Killing Steam process if running..."
    let procs = (ps | where name == "Steam.exe")
    if ($procs | length) == 0 {
        success "No Steam process running."
    } else {
        let kill_results = ($procs | each { kill $in.pid | complete })
        if ($kill_results | any { $in.exit_code != 0 }) {
            warn "Could not kill all Steam processes."
            $errors = ($errors | append "kill_steam")
        } else {
            success "Steam process(es) killed."
        }
    }
}

if $dry_run {
    log_dryrun "No changes were made."
}

if ($errors | length) == 0 {
    success "Steam installed. Please log in to Steam and install Rust (Facepunch, appid 252490) via the Steam client."
    exit 0
} else {
    let error_msg = ($errors | str join ", ")
    error $"The following steps failed: ($error_msg)"
    exit 1
}
