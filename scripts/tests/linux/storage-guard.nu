#!/usr/bin/env nu
# Defensive pre-reboot storage guard for NixOS
# - Verifies configured root/boot devices resolve on the current system
# - Confirms filesystem types match
# - Ensures stable identifiers are used (by-uuid/partuuid/label)
# - Asserts required initrd modules are present for the detected storage stack

let flake = ".#nixosConfigurations.nixos.config"

# Helper to eval a nix attribute to raw string
def nix_raw [attr: string] {
  ^nix eval --extra-experimental-features "nix-command flakes" --raw $"($flake).($attr)" | str trim
}

# Helper to eval a nix attribute to json -> value
def nix_json [attr: string] {
  ^nix eval --extra-experimental-features "nix-command flakes" --json $"($flake).($attr)" | from json
}

# Resolve a device path, returns resolved path or empty
def resolve_device [path: string] {
  if ($path | is-empty) { return "" }
  if not ($path | path exists) { return "" }
  let resolved = (^readlink -f $path | str trim)
  if ($resolved | is-empty) { return "" } else { return $resolved }
}

# Determine required modules based on device/driver heuristics
# This is a heuristic; presence is better-than-nothing
def infer_required_modules [root_dev: string, fs_type: string] {
  mut mods = ["sd_mod"]
  if $root_dev =~ "/nvme" { $mods = ($mods | append "nvme") }
  if $root_dev =~ "/vd" { $mods = ($mods | append "virtio_blk") }
  if $root_dev =~ "/md" { $mods = ($mods | append "raid1" | append "raid0" | append "raid456") }
  if $root_dev =~ "/dm-" { $mods = ($mods | append "dm_mod") }
  if $fs_type == "ext4" { $mods = ($mods | append "ext4") }
  if $fs_type == "xfs" { $mods = ($mods | append "xfs") }
  if $fs_type == "btrfs" { $mods = ($mods | append "btrfs") }
  $mods | uniq
}

# Main
let root_device = (nix_raw 'fileSystems."/".device' | default "")
let root_fs = (nix_raw 'fileSystems."/".fsType' | default "")
let boot_device = (nix_raw 'fileSystems."/boot".device' | default "")
let boot_fs = (nix_raw 'fileSystems."/boot".fsType' | default "")

# Basic validations
if ($root_device | is-empty) {
  print "❌ No configured root device found in flake"; exit 1
}

if not ($root_device =~ "/dev/disk/by-") {
  print $"❌ Root device is not using a stable identifier: ($root_device)"; exit 1
}

# Live system reality
let root_uuid_live = (^findmnt -no UUID / | str trim)
let root_resolved = (resolve_device $root_device)

if ($root_resolved | is-empty) {
  print $"❌ Configured root does not resolve on this system: ($root_device)"; exit 1
}

# If by-uuid was used, check it matches live UUID
if ($root_device =~ "/by-uuid/") and ($root_uuid_live | is-not-empty) {
  let cfg_uuid = ($root_device | path basename)
  if $cfg_uuid != $root_uuid_live {
    print $"❌ Config root UUID ($cfg_uuid) != live root UUID ($root_uuid_live)"; exit 1
  }
}

# Filesystem type check (best-effort)
let root_fs_live = (^findmnt -no FSTYPE / | str trim)
if ($root_fs | is-not-empty) and ($root_fs_live | is-not-empty) and ($root_fs != $root_fs_live) {
  print $"❌ Config root fsType ($root_fs) != live root fsType ($root_fs_live)"; exit 1
}

# Initrd modules presence check
let initrd_mods = (nix_json 'boot.initrd.availableKernelModules')
let required_mods = (infer_required_modules $root_resolved $root_fs_live)
let missing = ($required_mods | where {|m| not ($initrd_mods | any {|x| $x == $m }) })
if ($missing | is-not-empty) {
  print $"❌ Missing required initrd modules: ($missing | str join ', ')"; exit 1
}

# Boot partition checks if present
if ($boot_device | is-not-empty) {
  if not ($boot_device =~ "/dev/disk/by-") {
    print $"❌ Boot device is not using a stable identifier: ($boot_device)"; exit 1
  }
  if ((resolve_device $boot_device) | is-empty) {
    print $"❌ Configured boot does not resolve on this system: ($boot_device)"; exit 1
  }
}

print "✅ Storage guard checks passed" 