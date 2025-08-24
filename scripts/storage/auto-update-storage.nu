#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-logging.nu *
use ../lib/unified-error-handling.nu *


# Auto-update storage configuration to prevent boot failures
# This script detects and fixes UUID mismatches before rebuilds

def main [
    --verbose (-v)      # Enable verbose output
    --dry-run (-n)      # Show what would be changed without modifying
    --force (-f)        # Force update even if validation passes
    --config (-c): path # Path to hardware configuration (default: /etc/nixos/hardware-configuration.nix)
] {
    let hardware_config = if ($config | is-empty) { 
        "/etc/nixos/hardware-configuration.nix" 
    } else { 
        $config 
    }
    
    print "🔍 Storage Configuration Auto-Update"
    print $"Checking: ($hardware_config)"
    print ""
    
    # Step 1: Detect current storage devices
    let current_storage = detect-current-storage $verbose
    
    if ($current_storage | is-empty) {
        print "❌ Failed to detect current storage configuration"
        exit 1
    }
    
    # Step 2: Parse configured storage from hardware-configuration.nix
    let configured_storage = parse-hardware-config $hardware_config $verbose
    
    # Step 3: Compare and identify mismatches
    let mismatches = compare-storage $current_storage $configured_storage $verbose
    
    if ($mismatches | is-empty) and (not $force) {
        print "✅ Storage configuration is up to date"
        return
    }
    
    if not ($mismatches | is-empty) {
        print "⚠️  Found storage mismatches:"
        $mismatches | each { |mismatch|
            print $"  • ($mismatch.type): configured=($mismatch.configured) → actual=($mismatch.actual)"
        }
        print ""
    }
    
    if $dry_run {
        print "🔍 Dry run mode - no changes will be made"
        print "Would update the following:"
        $mismatches | each { |mismatch|
            print $"  • Replace ($mismatch.configured) with ($mismatch.actual)"
        }
        return
    }
    
    # Step 4: Create backup
    let backup_path = create-backup $hardware_config
    print $"📦 Created backup: ($backup_path)"
    
    # Step 5: Update configuration
    try {
        update-hardware-config $hardware_config $mismatches $verbose
        print "✅ Successfully updated storage configuration"
        
        # Step 6: Validate the update
        if (validate-storage-config $hardware_config) {
            print "✅ Configuration validated successfully"
        } else {
            print "❌ Validation failed, restoring backup..."
            cp $backup_path $hardware_config
            exit 1
        }
    } catch { |err|
        print $"❌ Update failed: ($err)"
        print "Restoring backup..."
        cp $backup_path $hardware_config
        exit 1
    }
}

# Detect current storage configuration from the system
def detect-current-storage [verbose: bool] {
    if $verbose { print "  Detecting current storage devices..." }
    
    mut storage = []
    
    # Get root filesystem
    let root_mount = (findmnt -n -o SOURCE / | str trim)
    
    if ($root_mount | str starts-with "/dev/") {
        # Get UUID and PARTUUID
        let root_uuid = (blkid -s UUID -o value $root_mount | str trim)
        let root_partuuid = (blkid -s PARTUUID -o value $root_mount | str trim)
        
        if not ($root_uuid | is-empty) {
            $storage = ($storage | append {
                device: $root_mount
                type: "uuid"
                value: $root_uuid
                mount: "/"
            })
        }
        
        if not ($root_partuuid | is-empty) {
            $storage = ($storage | append {
                device: $root_mount
                type: "partuuid"  
                value: $root_partuuid
                mount: "/"
            })
        }
    }
    
    # Get swap devices
    if ("/proc/swaps" | path exists) {
        let swap_devices = (
            open /proc/swaps 
            | lines 
            | skip 1 
            | parse "{device} {type} {size} {used} {priority}"
            | where device starts-with "/dev/"
        )
        
        for swap in $swap_devices {
            let swap_uuid = (blkid -s UUID -o value $swap.device | str trim)
            if not ($swap_uuid | is-empty) {
                $storage = ($storage | append {
                    device: $swap.device
                    type: "uuid"
                    value: $swap_uuid
                    mount: "swap"
                })
            }
        }
    }
    
    # Get boot partition if separate
    let boot_mount = (findmnt -n -o SOURCE /boot | str trim)
    if not ($boot_mount | is-empty) and ($boot_mount != $root_mount) {
        let boot_uuid = (blkid -s UUID -o value $boot_mount | str trim)
        if not ($boot_uuid | is-empty) {
            $storage = ($storage | append {
                device: $boot_mount
                type: "uuid"
                value: $boot_uuid
                mount: "/boot"
            })
        }
    }
    
    if $verbose {
        print "  Found storage devices:"
        $storage | each { |dev|
            print $"    • ($dev.mount): ($dev.type)=($dev.value) \(($dev.device)\)"
        }
    }
    
    return $storage
}

# Parse storage configuration from hardware-configuration.nix
def parse-hardware-config [config_path: path, verbose: bool] {
    if $verbose { print $"  Parsing ($config_path)..." }
    
    if not ($config_path | path exists) {
        print $"❌ Configuration file not found: ($config_path)"
        exit 1
    }
    
    let content = (open $config_path)
    mut configured = []
    
    # Extract UUID references
    let uuid_pattern = 'by-uuid/([a-f0-9-]+)'
    let uuids = ($content | parse -r $uuid_pattern)
    
    for uuid in $uuids {
        $configured = ($configured | append {
            type: "uuid"
            value: $uuid.capture0
            original: $"by-uuid/($uuid.capture0)"
        })
    }
    
    # Extract PARTUUID references
    let partuuid_pattern = 'by-partuuid/([a-f0-9-]+)'
    let partuuids = ($content | parse -r $partuuid_pattern)
    
    for partuuid in $partuuids {
        $configured = ($configured | append {
            type: "partuuid"
            value: $partuuid.capture0
            original: $"by-partuuid/($partuuid.capture0)"
        })
    }
    
    # Extract label references
    let label_pattern = 'by-label/([^"]+)'
    let labels = ($content | parse -r $label_pattern)
    
    for label in $labels {
        $configured = ($configured | append {
            type: "label"
            value: $label.capture0
            original: $"by-label/($label.capture0)"
        })
    }
    
    if $verbose {
        print "  Found configured storage:"
        $configured | each { |cfg|
            print $"    • ($cfg.type): ($cfg.value)"
        }
    }
    
    return $configured
}

# Compare current and configured storage
def compare-storage [current: list, configured: list, verbose: bool] {
    if $verbose { print "  Comparing storage configurations..." }
    
    mut mismatches = []
    
    for cfg in $configured {
        # Check if this configured value exists in current storage
        let exists = (
            $current 
            | where type == $cfg.type and value == $cfg.value
            | length
        ) > 0
        
        if not $exists {
            # Try to find the correct value for this type
            if $cfg.type == "uuid" {
                # Find the actual UUID for root
                let root_storage = ($current | where mount == "/" and type == "uuid" | first)
                
                if not ($root_storage | is-empty) {
                    $mismatches = ($mismatches | append {
                        type: "uuid"
                        configured: $cfg.value
                        actual: $root_storage.value
                        original: $cfg.original
                        replacement: $"by-uuid/($root_storage.value)"
                    })
                }
            }
        }
    }
    
    return $mismatches
}

# Create backup of hardware configuration
def create-backup [config_path: path] {
    let timestamp = (date now | format date "%Y%m%d-%H%M%S")
    let backup_path = $"($config_path).backup.($timestamp)"
    
    cp $config_path $backup_path
    return $backup_path
}

# Update hardware configuration with correct values
def update-hardware-config [config_path: path, mismatches: list, verbose: bool] {
    if $verbose { print "  Updating configuration..." }
    
    mut content = (open $config_path)
    
    for mismatch in $mismatches {
        if $verbose {
            print $"    Replacing ($mismatch.original) with ($mismatch.replacement)"
        }
        
        $content = ($content | str replace -a $mismatch.original $mismatch.replacement)
    }
    
    # Write updated content
    $content | save -f $config_path
}

# Validate storage configuration
def validate-storage-config [config_path: path] {
    let configured = parse-hardware-config $config_path false
    mut all_valid = true
    
    for cfg in $configured {
        if $cfg.type == "uuid" {
            # Check if UUID exists
            let exists = (do { blkid -U $cfg.value } | complete | get exit_code) == 0
            if not $exists {
                print $"  ❌ UUID not found: ($cfg.value)"
                $all_valid = false
            }
        } else if $cfg.type == "partuuid" {
            # Check if PARTUUID exists
            let exists = (do { blkid -t $"PARTUUID=($cfg.value)" } | complete | get exit_code) == 0
            if not $exists {
                print $"  ❌ PARTUUID not found: ($cfg.value)"
                $all_valid = false
            }
        }
    }
    
    return $all_valid
}