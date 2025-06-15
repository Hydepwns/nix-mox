{ pkgs }:
pkgs.mkShell {
  buildInputs = [
    # Base tools from default shell
    pkgs.nushell
    pkgs.git
    pkgs.nix
    pkgs.nixpkgs-fmt
    pkgs.shellcheck
    pkgs.coreutils
    pkgs.fd
    pkgs.ripgrep

    # ZFS-specific tools
    pkgs.zfs           # ZFS utilities
    pkgs.zfs-stats     # ZFS statistics
    pkgs.zfs-snap-diff # ZFS snapshot diff tool
    pkgs.zfs-auto-snapshot # Automatic ZFS snapshots
    pkgs.zfs-snapshot-diff # ZFS snapshot diff tool
    pkgs.zfs-snap-mgmt # ZFS snapshot management
    pkgs.zfs-tools     # Additional ZFS tools
    pkgs.zfs-dkms      # ZFS kernel modules
    pkgs.zfs-stats     # ZFS statistics
    pkgs.zfs-snap-diff # ZFS snapshot diff tool
    pkgs.zfs-auto-snapshot # Automatic ZFS snapshots
    pkgs.zfs-snapshot-diff # ZFS snapshot diff tool
    pkgs.zfs-snap-mgmt # ZFS snapshot management
    pkgs.zfs-tools     # Additional ZFS tools
    pkgs.zfs-dkms      # ZFS kernel modules

    # Performance testing tools
    pkgs.fio           # Flexible I/O tester
    pkgs.iozone3       # Filesystem benchmark
    pkgs.bonnie++      # Filesystem benchmark
    pkgs.hdparm        # Hard disk parameters
    pkgs.smartmontools # S.M.A.R.T. monitoring
  ];

  shellHook = ''
    echo "Welcome to the nix-mox ZFS development shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo "  - ZFS utilities and tools"
    echo "  - Performance testing tools"
    echo ""
    echo "ZFS-specific commands:"
    echo "  - zpool: ZFS pool management"
    echo "  - zfs: ZFS filesystem management"
    echo "  - zfs-stats: ZFS statistics"
    echo "  - zfs-snap-diff: ZFS snapshot diff tool"
    echo "  - zfs-auto-snapshot: Automatic ZFS snapshots"
    echo "  - zfs-snapshot-diff: ZFS snapshot diff tool"
    echo "  - zfs-snap-mgmt: ZFS snapshot management"
    echo "  - zfs-tools: Additional ZFS tools"
    echo ""
    echo "Performance testing tools:"
    echo "  - fio: Flexible I/O tester"
    echo "  - iozone3: Filesystem benchmark"
    echo "  - bonnie++: Filesystem benchmark"
    echo "  - hdparm: Hard disk parameters"
    echo "  - smartmontools: S.M.A.R.T. monitoring"
  '';
}
