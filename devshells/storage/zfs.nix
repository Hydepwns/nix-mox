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
  ] ++ (pkgs.lib.filter (pkg: pkg != null) [
    pkgs.zfs or null
    pkgs.zfsUnstable or null
    pkgs.zfs-auto-snapshot or null
    pkgs.zfs-snap-diff or null
    pkgs.zfs-diff or null
    pkgs.zfs-snapshot or null
    pkgs.zfs-prune-snapshots or null
    pkgs.zfs-stats or null
    pkgs.zfs-dkms or null
    pkgs.zfs-kernel or null
    pkgs.zfs-test or null
    pkgs.zfs-docs or null
    pkgs.zfs-scripts or null
    pkgs.zfs-utils or null
    pkgs.zfs-dkms-unstable or null
    pkgs.zfs-kernel-unstable or null
    pkgs.zfs-test-unstable or null
    pkgs.zfs-docs-unstable or null
  ]) ++ [
    pkgs.fio
    pkgs.smartmontools
    pkgs.hdparm
    pkgs.nvme-cli
    pkgs.lsscsi
    pkgs.sdparm
    pkgs.hdparm
    pkgs.sg3_utils
  ];

  shellHook = ''
    # Function to show help menu
    show_help() {
      echo "Welcome to the nix-mox ZFS shell!"
      echo ""
      echo "🔧 ZFS Tools"
      echo "-----------"
      ${if pkgs ? zfs then ''
      echo "zfs: (v${pkgs.zfs.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zpool list                    # List pools"
      echo "    - zfs list                      # List datasets"
      echo "    - zfs snapshot                  # Create snapshot"
      echo "    Dependencies:"
      echo "    - Requires: Linux kernel"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-auto-snapshot then ''
      echo "zfs-auto-snapshot: (v${pkgs.zfs-auto-snapshot.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-auto-snapshot             # Create snapshots"
      echo "    - zfs-auto-snapshot --help      # Show help"
      echo "    Configuration:"
      echo "    - /etc/cron.d/zfs-auto-snapshot"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-snap-diff then ''
      echo "zfs-snap-diff: (v${pkgs.zfs-snap-diff.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-snap-diff                 # Show differences"
      echo "    - zfs-snap-diff --help          # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-diff then ''
      echo "zfs-diff: (v${pkgs.zfs-diff.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-diff                      # Show differences"
      echo "    - zfs-diff --help               # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-snapshot then ''
      echo "zfs-snapshot: (v${pkgs.zfs-snapshot.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-snapshot                  # Create snapshot"
      echo "    - zfs-snapshot --help           # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-prune-snapshots then ''
      echo "zfs-prune-snapshots: (v${pkgs.zfs-prune-snapshots.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-prune-snapshots           # Prune snapshots"
      echo "    - zfs-prune-snapshots --help    # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-stats then ''
      echo "zfs-stats: (v${pkgs.zfs-stats.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-stats                     # Show statistics"
      echo "    - zfs-stats --help              # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-tools then ''
      echo "zfs-tools: (v${pkgs.zfs-tools.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-tools                     # Show tools"
      echo "    - zfs-tools --help              # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-dkms then ''
      echo "zfs-dkms: (v${pkgs.zfs-dkms.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-dkms                      # Show DKMS status"
      echo "    - zfs-dkms --help               # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-kernel then ''
      echo "zfs-kernel: (v${pkgs.zfs-kernel.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-kernel                    # Show kernel status"
      echo "    - zfs-kernel --help             # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-test then ''
      echo "zfs-test: (v${pkgs.zfs-test.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-test                      # Run tests"
      echo "    - zfs-test --help               # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-docs then ''
      echo "zfs-docs: (v${pkgs.zfs-docs.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-docs                      # Show documentation"
      echo "    - zfs-docs --help               # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-scripts then ''
      echo "zfs-scripts: (v${pkgs.zfs-scripts.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-scripts                   # Show scripts"
      echo "    - zfs-scripts --help            # Show help"
      echo ""
      '' else ""}
      ${if pkgs ? zfs-utils then ''
      echo "zfs-utils: (v${pkgs.zfs-utils.version}) [🐧 Linux only]"
      echo "    Commands:"
      echo "    - zfs-utils                     # Show utilities"
      echo "    - zfs-utils --help              # Show help"
      echo ""
      '' else ""}
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
