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

    # ZFS tools
    pkgs.zfs              # ZFS utilities
    pkgs.zfsUnstable      # Latest ZFS features
    pkgs.zfs-auto-snapshot # Automatic snapshots
    pkgs.zfs-snap-diff    # Snapshot diff tool
    pkgs.zfs-diff         # ZFS diff tool
    pkgs.zfs-snapshot     # Snapshot management
    pkgs.zfs-prune-snapshots # Snapshot pruning
    pkgs.zfs-stats        # ZFS statistics
    pkgs.zfs-dkms         # ZFS kernel module
    pkgs.zfs-kernel       # ZFS kernel module
    pkgs.zfs-test         # ZFS test suite
    pkgs.zfs-docs         # ZFS documentation
    pkgs.zfs-scripts      # ZFS scripts
    pkgs.zfs-utils        # ZFS utilities
    pkgs.zfs-dkms-unstable # Latest ZFS kernel module
    pkgs.zfs-kernel-unstable # Latest ZFS kernel module
    pkgs.zfs-test-unstable # Latest ZFS test suite
    pkgs.zfs-docs-unstable # Latest ZFS documentation

    # Storage testing tools
    pkgs.fio            # I/O performance testing
    pkgs.smartmontools  # SMART monitoring
    pkgs.hdparm        # Hard disk parameters
    pkgs.nvme-cli      # NVMe management
    pkgs.lsscsi        # SCSI device listing
    pkgs.sdparm        # SCSI disk parameters
    pkgs.hdparm        # ATA/IDE disk parameters
    pkgs.sg3_utils     # SCSI generic utilities
  ];

  shellHook = ''
    # Function to show help menu
    show_help() {
      echo "Welcome to the nix-mox ZFS shell!"
      echo ""
      echo "🔧 ZFS Tools"
      echo "-----------"
      echo "zfs: (v${pkgs.zfs.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zpool list                    # List pools"
      echo "    - zfs list                      # List datasets"
      echo "    - zfs snapshot                  # Create snapshot"
      echo "    Dependencies:"
      echo "    - Requires: Linux kernel"
      echo ""
      echo "zfs-auto-snapshot: (v${pkgs.zfs-auto-snapshot.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-auto-snapshot             # Create snapshots"
      echo "    - zfs-auto-snapshot --help      # Show help"
      echo "    Configuration:"
      echo "    - /etc/cron.d/zfs-auto-snapshot"
      echo ""
      echo "zfs-snap-diff: (v${pkgs.zfs-snap-diff.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-snap-diff                 # Show differences"
      echo "    - zfs-snap-diff --help          # Show help"
      echo ""
      echo "zfs-diff: (v${pkgs.zfs-diff.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-diff                      # Show differences"
      echo "    - zfs-diff --help               # Show help"
      echo ""
      echo "zfs-snapshot: (v${pkgs.zfs-snapshot.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-snapshot                  # Create snapshot"
      echo "    - zfs-snapshot --help           # Show help"
      echo ""
      echo "zfs-prune-snapshots: (v${pkgs.zfs-prune-snapshots.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-prune-snapshots           # Prune snapshots"
      echo "    - zfs-prune-snapshots --help    # Show help"
      echo ""
      echo "zfs-stats: (v${pkgs.zfs-stats.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-stats                     # Show statistics"
      echo "    - zfs-stats --help              # Show help"
      echo ""
      echo "zfs-tools: (v${pkgs.zfs-tools.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-tools                     # Show tools"
      echo "    - zfs-tools --help              # Show help"
      echo ""
      echo "zfs-dkms: (v${pkgs.zfs-dkms.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-dkms                      # Show DKMS status"
      echo "    - zfs-dkms --help               # Show help"
      echo ""
      echo "zfs-kernel: (v${pkgs.zfs-kernel.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-kernel                    # Show kernel status"
      echo "    - zfs-kernel --help             # Show help"
      echo ""
      echo "zfs-test: (v${pkgs.zfs-test.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-test                      # Run tests"
      echo "    - zfs-test --help               # Show help"
      echo ""
      echo "zfs-docs: (v${pkgs.zfs-docs.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-docs                      # Show documentation"
      echo "    - zfs-docs --help               # Show help"
      echo ""
      echo "zfs-scripts: (v${pkgs.zfs-scripts.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-scripts                   # Show scripts"
      echo "    - zfs-scripts --help            # Show help"
      echo ""
      echo "zfs-utils: (v${pkgs.zfs-utils.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-utils                     # Show utilities"
      echo "    - zfs-utils --help              # Show help"
      echo ""
      echo "📝 Quick Start"
      echo "------------"
      echo "1. List pools and datasets:"
      echo "   zpool list                      # List pools"
      echo "   zfs list                        # List datasets"
      echo ""
      echo "2. Create and manage snapshots:"
      echo "   zfs snapshot                    # Create snapshot"
      echo "   zfs-snap-diff                   # Show differences"
      echo ""
      echo "3. Prune old snapshots:"
      echo "   zfs-prune-snapshots             # Prune snapshots"
      echo "   zfs-stats                       # Show statistics"
      echo ""
      echo "For more information, see docs/."
    }

    # Show initial help menu
    show_help

    # Add help command to shell
    echo ""
    echo "💡 Tip: Type 'help' to show this menu again"
    echo "💡 Tip: Type 'which-shell' to see which shell you're in"
    echo ""
    alias help='show_help'
    alias which-shell='echo "You are in the nix-mox ZFS shell"'
  '';
}
