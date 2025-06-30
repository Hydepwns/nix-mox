#!/usr/bin/env nu

# Wrapper script for the gaming setup wizard
# Usage: nu scripts/run-gaming-wizard.nu [--dry-run]

let args = ($env.args? | default [])
let dry_run = ($args | where $it == "--dry-run" | length) > 0

if $dry_run {
    $env.DRY_RUN = true
    nu scripts/setup-gaming-wizard.nu
} else {
    nu scripts/setup-gaming-wizard.nu
} 