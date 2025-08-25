#!/usr/bin/env nu

# Import unified libraries
use ../lib/validators.nu
use ../lib/logging.nu


# Storage configuration validator
# Validates all storage references in hardware-configuration.nix

def main [
    --config (-c): path = "/etc/nixos/hardware-configuration.nix"  # Hardware config path
    --verbose (-v)                                                  # Verbose output
    --fix (-f)                                                      # Attempt to fix issues
] {
    print "🔍 Storage Configuration Validator"
    print "=================================="
    print ""
    
    if not ($config | path exists) {
        print $"❌ Configuration file not found: ($config)"
        exit 1
    }
    
    print $"Checking: ($config)"
    print ""
    
    # Parse all storage references
    let storage_refs = parse-storage-references $config $verbose
    
    if ($storage_refs | is-empty) {
        print "⚠️  No storage references found in configuration"
        return
    }
    
    # Validate each reference
    let validation_results = validate-references $storage_refs $verbose
    
    # Report results
    let errors = ($validation_results | where status == "error")
    let warnings = ($validation_results | where status == "warning")
    let valid = ($validation_results | where status == "valid")
    
    print "📊 Validation Summary:"
    print $"  ✅ Valid:    ($valid | length)"
    print $"  ⚠️  Warnings: ($warnings | length)"
    print $"  ❌ Errors:   ($errors | length)"
    print ""
    
    # Show details for problems
    if not ($warnings | is-empty) {
        print "⚠️  Warnings:"
        $warnings | each { |w|
            print $"  • ($w.type)/($w.value): ($w.message)"
        }
        print ""
    }
    
    if not ($errors | is-empty) {
        print "❌ Errors:"
        $errors | each { |e|
            print $"  • ($e.type)/($e.value): ($e.message)"
            if not ($e.suggestion | is-empty) {
                print $"    → Suggestion: ($e.suggestion)"
            }
        }
        print ""
        
        if $fix {
            print "🔧 Attempting automatic fixes..."
            fix-storage-issues $config $errors
        } else {
            print "💡 Run with --fix to attempt automatic repairs"
            print "   Or run: nu scripts/storage/auto-update-storage.nu"
        }
        
        exit 1
    }
    
    print "✅ All storage references are valid!"
}

# Parse storage references from configuration
def parse-storage-references [config_path: path, verbose: bool] {
    let content = (open $config_path)
    mut references = []
    
    # UUID references
    let uuid_matches = ($content | parse -r 'by-uuid/([a-f0-9-]+)')
    for match in $uuid_matches {
        $references = ($references | append {
            type: "uuid"
            value: $match.capture0
            path: $"by-uuid/($match.capture0)"
        })
    }
    
    # PARTUUID references
    let partuuid_matches = ($content | parse -r 'by-partuuid/([a-f0-9-]+)')
    for match in $partuuid_matches {
        $references = ($references | append {
            type: "partuuid"
            value: $match.capture0
            path: $"by-partuuid/($match.capture0)"
        })
    }
    
    # Label references
    let label_matches = ($content | parse -r 'by-label/([^"\\s]+)')
    for match in $label_matches {
        $references = ($references | append {
            type: "label"
            value: $match.capture0
            path: $"by-label/($match.capture0)"
        })
    }
    
    # Device path references
    let device_matches = ($content | parse -r '(/dev/[^"\\s]+)')
    for match in $device_matches {
        # Filter out by-uuid/by-label/by-partuuid paths
        if not ($match.capture0 | str contains "by-") {
            $references = ($references | append {
                type: "device"
                value: $match.capture0
                path: $match.capture0
            })
        }
    }
    
    if $verbose {
        print $"Found ($references | length) storage references:"
        $references | each { |ref|
            print $"  • ($ref.type): ($ref.value)"
        }
        print ""
    }
    
    return $references
}

# Validate each storage reference
def validate-references [references: list, verbose: bool] {
    mut results = []
    
    for ref in $references {
        let result = (validate-single-reference $ref $verbose)
        $results = ($results | append $result)
    }
    
    return $results
}

# Validate a single storage reference
def validate-single-reference [ref: record, verbose: bool] {
    if $verbose {
        print $"  Checking ($ref.type): ($ref.value)..."
    }
    
    if $ref.type == "uuid" {
        # Check if UUID exists
        let check = (do { blkid -U $ref.value } | complete)
        
        if $check.exit_code == 0 {
            let device = ($check.stdout | str trim)
            return {
                ...$ref
                status: "valid"
                message: $"Found at ($device)"
                device: $device
            }
        } else {
            # Try to find similar UUIDs
            let all_uuids = (blkid -s UUID | parse -r 'UUID="([^"]+)"' | get capture0)
            let suggestion = find-similar-uuid $ref.value $all_uuids
            
            return {
                ...$ref
                status: "error"
                message: "UUID not found in system"
                suggestion: $suggestion
            }
        }
        
    } else if $ref.type == "partuuid" {
        # Check if PARTUUID exists
        let check = (do { blkid -t $"PARTUUID=($ref.value)" } | complete)
        
        if $check.exit_code == 0 {
            let device = ($check.stdout | str trim | split row ":" | get 0)
            return {
                ...$ref
                status: "valid"
                message: $"Found at ($device)"
                device: $device
            }
        } else {
            return {
                ...$ref
                status: "error"
                message: "PARTUUID not found in system"
                suggestion: "Check if partition table has changed"
            }
        }
        
    } else if $ref.type == "label" {
        # Check if label exists
        let check = (do { blkid -L $ref.value } | complete)
        
        if $check.exit_code == 0 {
            let device = ($check.stdout | str trim)
            return {
                ...$ref
                status: "valid"
                message: $"Found at ($device)"
                device: $device
            }
        } else {
            return {
                ...$ref
                status: "error"
                message: "Label not found in system"
                suggestion: $"Create label with: e2label <device> ($ref.value)"
            }
        }
        
    } else if $ref.type == "device" {
        # Check if device exists
        if ($ref.value | path exists) {
            # Check if it's a block device
            let is_block = (ls -la $ref.value | get 0.type | str contains "block")
            
            if $is_block {
                return {
                    ...$ref
                    status: "warning"
                    message: "Using device path (not recommended)"
                    suggestion: "Consider using UUID instead for stability"
                }
            } else {
                return {
                    ...$ref
                    status: "error"
                    message: "Path exists but is not a block device"
                    suggestion: ""
                }
            }
        } else {
            return {
                ...$ref
                status: "error"
                message: "Device path does not exist"
                suggestion: "Device may have been renamed or removed"
            }
        }
    }
    
    return {
        ...$ref
        status: "unknown"
        message: "Unknown reference type"
        suggestion: ""
    }
}

# Find similar UUIDs (for typo detection)
def find-similar-uuid [target: string, uuids: list] {
    for uuid in $uuids {
        # Simple similarity check - if most characters match
        let target_chars = ($target | split chars)
        let uuid_chars = ($uuid | split chars)
        
        if ($target_chars | length) == ($uuid_chars | length) {
            let matches = (
                $target_chars 
                | enumerate 
                | where { |it| $it.item == ($uuid_chars | get $it.index) }
                | length
            )
            
            let similarity = ($matches / ($target_chars | length))
            
            if $similarity > 0.8 {
                return $"Did you mean: ($uuid)?"
            }
        }
    }
    
    return "Run 'blkid' to see all available UUIDs"
}

# Attempt to fix storage issues
def fix-storage-issues [config_path: path, errors: list] {
    print "🔧 Attempting to fix storage issues..."
    
    # Group errors by type
    let uuid_errors = ($errors | where type == "uuid")
    let device_errors = ($errors | where type == "device")
    
    # For UUID errors, try to map to correct UUIDs
    if not ($uuid_errors | is-empty) {
        print "  Fixing UUID references..."
        
        # Get current root device UUID
        let root_device = (findmnt -n -o SOURCE /)
        let root_uuid = (blkid -s UUID -o value $root_device | str trim)
        
        if not ($root_uuid | is-empty) {
            print $"  Found root UUID: ($root_uuid)"
            
            # Create backup
            let backup = $"($config_path).backup.(date now | format date '%Y%m%d-%H%M%S')"
            cp $config_path $backup
            print $"  Created backup: ($backup)"
            
            # Update configuration
            mut content = (open $config_path)
            
            for error in $uuid_errors {
                print $"  Replacing ($error.value) with ($root_uuid)"
                $content = ($content | str replace -a $"by-uuid/($error.value)" $"by-uuid/($root_uuid)")
            }
            
            $content | save -f $config_path
            print "  ✅ Updated configuration"
        }
    }
    
    # For device path warnings, suggest UUID conversion
    if not ($device_errors | is-empty) {
        print "  Converting device paths to UUIDs..."
        
        for error in $device_errors {
            if ($error.value | path exists) {
                let uuid = (blkid -s UUID -o value $error.value | str trim)
                if not ($uuid | is-empty) {
                    print $"  Device ($error.value) has UUID: ($uuid)"
                    print $"  Consider replacing with: by-uuid/($uuid)"
                }
            }
        }
    }
    
    print "✅ Fix attempt completed - please re-run validation"
}