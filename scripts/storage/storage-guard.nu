#!/usr/bin/env nu

# Import consolidated libraries
use ../lib/logging.nu *
use ../lib/command-wrapper.nu *
use ../lib/validators.nu *

# Defensive pre-reboot storage guard for NixOS
# - Verifies configured root/boot devices resolve on the current system
# - Confirms filesystem types match
# - Ensures stable identifiers are used (by-uuid/partuuid/label)
# - Asserts required initrd modules are present for the detected storage stack

let flake = ".#nixosConfigurations.nixos.config"

# Helper to eval a nix attribute to raw string
def nix_raw [attr: string] {
  let result = (nix_eval $"($flake).($attr)" --context "storage-guard")
  if $result.exit_code == 0 { $result.stdout | str trim } else { "" }
}

# Helper to eval a nix attribute to json -> value
def nix_json [attr: string] {
  let result = (execute_command ["nix" "eval" "--extra-experimental-features" "nix-command flakes" "--json" $"($flake).($attr)"] --context "storage-guard")
  if $result.exit_code == 0 { $result.stdout | from json } else { {} }
}

# Resolve a device path, returns resolved path or empty
def resolve_device [path: string] {
  if ($path | is-empty) { return "" }
  if not ($path | path exists) { return "" }
  let resolved = (^readlink -f $path | str trim)
  if ($resolved | is-empty) { return "" } else { return $resolved }
}

# Get current partuuid for a device
def get_partuuid [device: string] {
  if ($device | is-empty) { return "" }
  try {
    ^sudo blkid $device | str replace -r '.*PARTUUID="([^"]+)".*' '$1' | str trim
  } catch {
    return ""
  }
}

# Get current UUID for a device
def get_uuid [device: string] {
  if ($device | is-empty) { return "" }
  try {
    ^sudo blkid $device | str replace -r '.*UUID="([^"]+)".*' '$1' | str trim
  } catch {
    return ""
  }
}

# Determine required modules based on device/driver heuristics
def infer_required_modules [root_dev: string, fs_type: string] {
  let base_mods = ["sd_mod"]
  let device_mods = if $root_dev =~ "/nvme" { ["nvme"] } else if $root_dev =~ "/vd" { ["virtio_blk"] } else if $root_dev =~ "/md" { ["raid1" "raid0" "raid456"] } else if $root_dev =~ "/dm-" { ["dm_mod"] } else { [] }
  let fs_mods = if $fs_type == "ext4" { ["ext4"] } else if $fs_type == "xfs" { ["xfs"] } else if $fs_type == "btrfs" { ["btrfs"] } else { [] }
  
  $base_mods | append $device_mods | append $fs_mods | uniq
}

# Main storage guard validation
def main [] {
  info "Starting storage guard validation" --context "storage-guard"
  
  let root_device = (nix_raw 'fileSystems."/".device' | default "")
  let root_fs = (nix_raw 'fileSystems."/".fsType' | default "")
  let boot_device = (nix_raw 'fileSystems."/boot".device' | default "")
  let boot_fs = (nix_raw 'fileSystems."/boot".fsType' | default "")
  
  # Basic validations
  if ($root_device | is-empty) {
    error "No configured root device found in flake" --context "storage-guard"
    return false
  }
  
  if not ($root_device =~ "/dev/disk/by-") {
    error $"Root device is not using a stable identifier: ($root_device)" --context "storage-guard"
    return false
  }
  
  # Live system reality
  let root_uuid_live = (^findmnt -no UUID / | str trim)
  let root_resolved = (resolve_device $root_device)
    
    if ($root_resolved | is-empty) {
      error $"Configured root does not resolve on this system: ($root_device)" --context "storage-guard"
      
      # If it's a partuuid issue, provide helpful information
      if ($root_device =~ "/by-partuuid/") {
        let expected_partuuid = ($root_device | path basename)
        let actual_root_dev = (^findmnt -no SOURCE / | str trim)
        let actual_partuuid = (get_partuuid $actual_root_dev)
        let actual_uuid = (get_uuid $actual_root_dev)
        
        info $"   Expected partuuid: ($expected_partuuid)" --context "storage-guard"
        info $"   Actual partuuid: ($actual_partuuid)" --context "storage-guard"
        info $"   Actual UUID: ($actual_uuid)" --context "storage-guard"
        info $"   Actual device: ($actual_root_dev)" --context "storage-guard"
        info "" --context "storage-guard"
        info "💡 To fix this, update your hardware configuration:" --context "storage-guard"
        info $"   fileSystems.\"/\" = {{" --context "storage-guard"
        info $"     device = \"/dev/disk/by-partuuid/($actual_partuuid)\";" --context "storage-guard"
        info $"     fsType = \"ext4\";" --context "storage-guard"
        info $"   }};" --context "storage-guard"
        info "" --context "storage-guard"
        info "   Or use UUID instead (more stable):" --context "storage-guard"
        info $"   fileSystems.\"/\" = {{" --context "storage-guard"
        info $"     device = \"/dev/disk/by-uuid/($actual_uuid)\";" --context "storage-guard"
        info $"     fsType = \"ext4\";" --context "storage-guard"
        info $"   }};" --context "storage-guard"
      }
      return false
    }
    
    # If by-uuid was used, check it matches live UUID
    if ($root_device =~ "/by-uuid/") and ($root_uuid_live | is-not-empty) {
      let cfg_uuid = ($root_device | path basename)
      if $cfg_uuid != $root_uuid_live {
        error $"Config root UUID ($cfg_uuid) != live root UUID ($root_uuid_live)" --context "storage-guard"
        return false
      }
    }
    
    # Filesystem type check (best-effort)
    let root_fs_live = (^findmnt -no FSTYPE / | str trim)
    if ($root_fs | is-not-empty) and ($root_fs_live | is-not-empty) and ($root_fs != $root_fs_live) {
      error $"Config root fsType ($root_fs) != live root fsType ($root_fs_live)" --context "storage-guard"
      return false
    }
    
    # Initrd modules presence check
    let initrd_mods = (nix_json 'boot.initrd.availableKernelModules')
    let required_mods = (infer_required_modules $root_resolved $root_fs_live)
    let missing = ($required_mods | where {|m| not ($initrd_mods | any {|x| $x == $m }) })
    if ($missing | is-not-empty) {
      error $"Missing required initrd modules: ($missing | str join ', ')" --context "storage-guard"
      return false
    }
    
    # Boot partition checks if present
    if ($boot_device | is-not-empty) {
      if not ($boot_device =~ "/dev/disk/by-") {
        error $"Boot device is not using a stable identifier: ($boot_device)" --context "storage-guard"
        return false
      }
      if ((resolve_device $boot_device) | is-empty) {
        error $"Configured boot does not resolve on this system: ($boot_device)" --context "storage-guard"
        return false
      }
    }
    
  success "Storage guard checks passed" --context "storage-guard"
  true
}

# Run the main function if script is executed directly
if $nu.current-exe? == null {
  main
}