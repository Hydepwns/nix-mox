{
  # Storage-related modules organized by functionality
  storage = import ./storage.nix;

  # Legacy ZFS module (for backward compatibility)
  zfs = import ./zfs;
  # Future storage modules can be added here
  # backup = import ./backup;
}
