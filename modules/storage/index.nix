{
  # Storage-related modules organized by functionality
  storage = import ./storage.nix;

  # Legacy ZFS module (for backward compatibility)
  zfs = import ./zfs/index.nix;

  # Storage templates
  templates = {
    zfs-ssd-caching = import ./templates/zfs-ssd-caching/zfs-ssd-caching.nix;
  };

  # Future storage modules can be added here
  # backup = import ./backup;
}
