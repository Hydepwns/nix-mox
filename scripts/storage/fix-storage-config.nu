#!/usr/bin/env nu

# Import unified libraries
use ../../lib/unified-checks.nu
use ../../lib/unified-logging.nu *
use ../../lib/unified-error-handling.nu *

# Fix storage configuration issues automatically
# - Detects mismatched partuuid/UUID in hardware configuration
# - Updates configuration with correct identifiers
# - Provides option to use UUID (more stable) or partuuid

let config_file = "/etc/nixos/hardware-configuration.nix"

# Helper to get current device identifiers
def get_current_identifiers [] {
  let root_dev = (^findmnt -no SOURCE / | str trim)
  let boot_dev = (^findmnt -no SOURCE /boot | str trim)
  
  let root_uuid = (^findmnt -no UUID / | str trim)
  let boot_uuid = (^findmnt -no UUID /boot | str trim)
  
  let root_partuuid = (^sudo blkid $root_dev | str replace -r '.*PARTUUID="([^"]+)".*' '$1' | str trim)
  let boot_partuuid = (^sudo blkid $boot_dev | str replace -r '.*PARTUUID="([^"]+)".*' '$1' | str trim)
  
  {
    root: {
      device: $root_dev
      uuid: $root_uuid
      partuuid: $root_partuuid
    }
    boot: {
      device: $boot_dev
      uuid: $boot_uuid
      partuuid: $boot_partuuid
    }
  }
}

# Helper to read current configuration
def read_config [] {
  let root_device = (^nix eval --extra-experimental-features "nix-command flakes" --raw ".#nixosConfigurations.nixos.config.fileSystems.\"/\".device" | str trim)
  let boot_device = (^nix eval --extra-experimental-features "nix-command flakes" --raw ".#nixosConfigurations.nixos.config.fileSystems.\"/boot\".device" | str trim)
  
  {
    root: $root_device
    boot: $boot_device
  }
}

# Helper to check if device resolves
def device_resolves [device: string] {
  if ($device | is-empty) { return false }
  if not ($device | path exists) { return false }
  let resolved = (^readlink -f $device | str trim)
  $resolved | is-not-empty
}

# Main function
def main [] {
  print "🔍 Analyzing storage configuration..."
  
  let current = (get_current_identifiers)
  let config = (read_config)
  
  print "Current system:"
  print $"  Root: ($current.root.device)"
  print $"    UUID: ($current.root.uuid)"
  print $"    PartUUID: ($current.root.partuuid)"
  print $"  Boot: ($current.boot.device)"
  print $"    UUID: ($current.boot.uuid)"
  print $"    PartUUID: ($current.boot.partuuid)"
  print $""
  print "Configuration:"
  print $"  Root: ($config.root)"
  print $"  Boot: ($config.boot)"
  print $""
  
  # Check for issues
  mut issues = []
  
  if not (device_resolves $config.root) {
    $issues = ($issues | append "root")
  }
  
  if not (device_resolves $config.boot) {
    $issues = ($issues | append "boot")
  }
  
  if ($issues | is-empty) {
    print "✅ No storage configuration issues detected"
    return
  }
  
  print $"❌ Issues detected: ($issues | str join ', ')"
  print $""
  
  # Ask user for preference
  print "Choose identifier type:"
  print "1. UUID (recommended - more stable)"
  print "2. partuuid (can change with partition table modifications)"
  print "3. Skip fix"
  
  let choice = (input "Enter choice (1-3): ")
  
  if $choice == "3" {
    print "Skipping fix"
    return
  }
  
  let use_uuid = ($choice == "1")
  
  # Create backup
  let timestamp = (date now | format date '%Y%m%d_%H%M%S')
  let backup_file = $"($config_file).backup.($timestamp)"
  ^cp $config_file $backup_file
  print $"📋 Backup created: ($backup_file)"
  
  # Read current config file
  let content = (open $config_file | str join "\n")
  
  # Update root device
  let new_root_device = if $use_uuid {
    $"/dev/disk/by-uuid/($current.root.uuid)"
  } else {
    $"/dev/disk/by-partuuid/($current.root.partuuid)"
  }
  
  let updated_content = ($content | str replace -r 'device = "/dev/disk/by-[^"]+";' $"device = \"($new_root_device)\";")
  
  # Update boot device if needed
  let final_content = if ($issues | any {|x| $x == "boot" }) {
    let new_boot_device = if $use_uuid {
      $"/dev/disk/by-uuid/($current.boot.uuid)"
    } else {
      $"/dev/disk/by-partuuid/($current.boot.partuuid)"
    }
    ($updated_content | str replace -r 'device = "/dev/disk/by-[^"]+";' $"device = \"($new_boot_device)\";")
  } else {
    $updated_content
  }
  
  # Write updated config
  $final_content | save $config_file
  
  print $"✅ Configuration updated:"
  print $"  Root: ($new_root_device)"
  if ($issues | any {|x| $x == "boot" }) {
    let new_boot_device = if $use_uuid {
      $"/dev/disk/by-uuid/($current.boot.uuid)"
    } else {
      $"/dev/disk/by-partuuid/($current.boot.partuuid)"
    }
    print $"  Boot: ($new_boot_device)"
  }
  print $""
  print "💡 Run 'nix run .#storage-guard' to verify the fix"
}

# Run main function
main 