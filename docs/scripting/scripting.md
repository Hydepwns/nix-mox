# Script Development Guide

## Script Structure

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "script-name"
    $env.SCRIPT_VERSION = "1.0.0"
}

def main [] {
    try {
        # Script implementation
    } catch {
        handle_error $"Script failed: ($env.LAST_ERROR)"
    }
}

main
```

## Package Scripts

### Proxmox Update Script

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "proxmox-update"
    $env.SCRIPT_VERSION = "1.0.0"
    $env.LOGFILE = "/var/log/proxmox-update.log"
}

def main [] {
    try {
        check_root
        log_info "Starting Proxmox update..."
        
        # Update package lists
        apt update | append-to-log $env.LOGFILE
        
        # Perform distribution upgrade
        apt -y dist-upgrade | append-to-log $env.LOGFILE
        
        # Remove unused packages
        apt -y autoremove | append-to-log $env.LOGFILE
        
        # Run Proxmox updates
        pveupdate | append-to-log $env.LOGFILE
        pveupgrade | append-to-log $env.LOGFILE
        
        log_success "Proxmox update complete"
    } catch {
        handle_error $"Update failed: ($env.LAST_ERROR)"
    }
}

main
```

### VZDump Backup Script

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "vzdump-backup"
    $env.SCRIPT_VERSION = "1.0.0"
    $env.LOGFILE = "/var/log/vzdump-backup.log"
    $env.STORAGE = "backup"
}

def backup_items [list_cmd: string, item_type: string] {
    let ids = (do { nu -c $list_cmd } | complete | get stdout | lines | skip 1 | split column " " | get column1)
    
    for id in $ids {
        log_info $"Backing up ($item_type) ($id)..."
        try {
            vzdump $id --storage $env.STORAGE --mode snapshot --compress zstd
            log_success $"Backed up ($item_type) ($id)"
        } catch {
            log_error $"Failed to back up ($item_type) ($id)"
        }
    }
}

def main [] {
    try {
        check_root
        log_info "Starting Proxmox backup..."
        
        # Backup VMs
        backup_items "qm list" "VM"
        
        # Backup containers
        backup_items "pct list" "CT"
        
        log_success "Backup complete"
    } catch {
        handle_error $"Backup failed: ($env.LAST_ERROR)"
    }
}

main
```

### ZFS Snapshot Script

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "zfs-snapshot"
    $env.SCRIPT_VERSION = "1.0.0"
    $env.LOGFILE = "/var/log/zfs-snapshot.log"
    $env.RETENTION_DAYS = 7
}

def create_snapshot [pool: string] {
    let timestamp = (date now | format date '%Y%m%d-%H%M%S')
    let snap_name = $"($pool)@snap-($timestamp)"
    
    try {
        zfs snapshot -r $snap_name
        log_success $"Created snapshot ($snap_name)"
    } catch {
        log_error $"Failed to create snapshot ($snap_name)"
    }
}

def prune_snapshots [pool: string] {
    let cutoff = ((date now) - ($env.RETENTION_DAYS * 24hr))
    let old_snaps = (zfs list -H -t snapshot -o name,creation | lines | split column " " | where {|x| $x.creation < $cutoff})
    
    for snap in $old_snaps {
        try {
            zfs destroy $snap.name
            log_success $"Pruned snapshot ($snap.name)"
        } catch {
            log_error $"Failed to prune snapshot ($snap.name)"
        }
    }
}

def main [] {
    try {
        check_root
        log_info "Starting ZFS snapshot management..."
        
        # Get list of pools
        let pools = (zfs list -H -o name | lines)
        
        for pool in $pools {
            create_snapshot $pool
            prune_snapshots $pool
        }
        
        log_success "ZFS snapshot management complete"
    } catch {
        handle_error $"ZFS snapshot management failed: ($env.LAST_ERROR)"
    }
}

main
```

## Core Utilities

### Error Handling

```nushell
def handle_error [error_msg: string, exit_code: int = 1] {
    log_error $error_msg
    if ($env.LOG_FILE? | is-not-empty) {
        log_error "Check log file: ($env.LOG_FILE)"
    }
    exit $exit_code
}
```

### Logging

```nushell
def log_info [message: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    print $"[INFO] ($timestamp) ($message)"
}

def log_error [message: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    print $"[ERROR] ($timestamp) ($message)"
}
```

### Platform Detection

```nushell
def detect_platform [] {
    let os = (sys | get host.name)
    match $os {
        "Linux" => "linux",
        "Darwin" => "darwin",
        "Windows" => "windows",
        _ => {
            log_error $"Unsupported OS: ($os)"
            exit 1
        }
    }
}
```

## Best Practices

1. Error Handling
   - Use try-catch blocks
   - Provide clear error messages
   - Log errors to file
   - Use appropriate exit codes

2. Logging
   - Use proper log levels
   - Include timestamps
   - Log to file for important ops
   - Enable debug mode when needed

3. Testing
   - Write unit tests
   - Include integration tests
   - Test platform-specific code
   - Use test fixtures

4. Code Organization
   - Keep functions focused
   - Use clear names
   - Include documentation
   - Follow consistent style
   - Guard platform-specific code

## Debugging

### Debug Mode

```nushell
# Enable debug mode
$env.DEBUG = true
# Or: nix-mox --script <script> --debug
```

### Script Logging

```nushell
# Set log file
$env.LOG_FILE = "script.log"
# Or: nix-mox --script <script> --log script.log
```

### Debug Techniques

1. Print variables: `print $"Value: ($variable)"`
2. Check output: `let output = (command | str trim)`

## Gaming Scripts

### Steam/Rust Update Script

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "steam-rust-update"
    $env.SCRIPT_VERSION = "1.0.0"
    $env.LOGFILE = "/var/log/steam-rust-update.log"
}

def main [] {
    try {
        log_info "Starting Steam/Rust update..."
        # Update logic
        log_success "Steam/Rust update complete"
    } catch {
        handle_error $"Update failed: ($env.LAST_ERROR)"
    }
}

main
```

### Game Performance Optimization Script

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "optimize-game-performance"
    $env.SCRIPT_VERSION = "1.0.0"
    $env.LOGFILE = "/var/log/optimize-game-performance.log"
}

def main [] {
    try {
        log_info "Starting game performance optimization..."
        # Optimization logic
        log_success "Game performance optimization complete"
    } catch {
        handle_error $"Optimization failed: ($env.LAST_ERROR)"
    }
}

main
```
