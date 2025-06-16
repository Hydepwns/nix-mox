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

    # ZFS and Linux-only tools
  ] ++ (if pkgs.stdenv.isLinux && pkgs.system == "x86_64-linux" then [
    pkgs.zfs           # ZFS utilities
    pkgs.fio           # Flexible I/O tester
    pkgs.iozone        # Filesystem benchmark
    pkgs.bonnie        # Filesystem benchmark
    pkgs.hdparm        # Hard disk parameters
    pkgs.smartmontools # S.M.A.R.T. monitoring
    pkgs.zfs-dkms     # ZFS kernel modules (x86_64-linux only)
  ] else []);

  shellHook = ''
    echo "Welcome to the nix-mox ZFS development shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo ""
    echo "🔧 ZFS Management"
    echo "---------------"
    echo "1. Pool Management:"
    echo "   # List pools"
    echo "   zpool list"
    echo ""
    echo "   # Create pool"
    echo "   zpool create mypool /dev/sdb"
    echo ""
    echo "   # Check pool status"
    echo "   zpool status mypool"
    echo ""
    echo "2. Dataset Management:"
    echo "   # List datasets"
    echo "   zfs list"
    echo ""
    echo "   # Create dataset"
    echo "   zfs create mypool/mydataset"
    echo ""
    echo "   # Set properties"
    echo "   zfs set compression=lz4 mypool/mydataset"
    echo ""
    echo "3. Snapshot Management:"
    echo "   # Create snapshot"
    echo "   zfs snapshot mypool/mydataset@snap1"
    echo ""
    echo "   # List snapshots"
    echo "   zfs list -t snapshot"
    echo ""
    echo "   # Rollback to snapshot"
    echo "   zfs rollback mypool/mydataset@snap1"
    echo ""
    echo "📝 Storage Patterns"
    echo "-----------------"
    echo "1. Pool Creation:"
    echo "   [Disks] -> [RAID] -> [Pool] -> [Datasets]"
    echo "   [Raw] -> [Redundancy] -> [Storage] -> [Organization]"
    echo ""
    echo "2. Snapshot Strategy:"
    echo "   [Dataset] -> [Snapshot] -> [Retention] -> [Cleanup]"
    echo "   [Data] -> [Point-in-time] -> [Policy] -> [Maintenance]"
    echo ""
    echo "3. Performance Tuning:"
    echo "   [Benchmark] -> [Analyze] -> [Tune] -> [Verify]"
    echo "   [Test] -> [Metrics] -> [Optimize] -> [Validate]"
    echo ""
    echo "🔍 ZFS Architecture"
    echo "-----------------"
    echo "                    [ZFS Pool]"
    echo "                        ↑"
    echo "                        |"
    echo "        +---------------+---------------+"
    echo "        ↓               ↓               ↓"
    echo "  [Datasets]     [Snapshots]      [Clones]"
    echo "        ↑               ↑               ↑"
    echo "        |               |               |"
    echo "  [Properties]    [Retention]     [Deduplication]"
    echo "        ↑               ↑               ↑"
    echo "        |               |               |"
    echo "  [Compression]   [Replication]    [Encryption]"
    echo ""
    echo "📚 Configuration Examples"
    echo "----------------------"
    echo "1. ZFS Pool Creation:"
    echo "   # Mirror"
    echo "   zpool create mypool mirror /dev/sdb /dev/sdc"
    echo ""
    echo "   # RAID-Z"
    echo "   zpool create mypool raidz /dev/sdb /dev/sdc /dev/sdd"
    echo ""
    echo "   # RAID-Z2"
    echo "   zpool create mypool raidz2 /dev/sdb /dev/sdc /dev/sdd /dev/sde"
    echo ""
    echo "2. Dataset Properties:"
    echo "   # Enable compression"
    echo "   zfs set compression=lz4 mypool/mydataset"
    echo ""
    echo "   # Set quota"
    echo "   zfs set quota=100G mypool/mydataset"
    echo ""
    echo "   # Enable deduplication"
    echo "   zfs set dedup=on mypool/mydataset"
    echo ""
    echo "3. Snapshot Management:"
    echo "   # Create snapshot"
    echo "   zfs snapshot -r mypool/mydataset@daily-$(date +%Y%m%d)"
    echo ""
    echo "   # List snapshots"
    echo "   zfs list -t snapshot -o name,creation,used"
    echo ""
    echo "   # Destroy old snapshots"
    echo "   zfs list -H -t snapshot -o name | grep 'daily-' | head -n -7 | xargs -n 1 zfs destroy"
    echo ""
    echo "4. Performance Testing:"
    echo "   # Random I/O"
    echo "   fio --name=randwrite --ioengine=libaio --iodepth=1 --rw=randwrite --bs=4k --direct=1 --size=1G"
    echo ""
    echo "   # Sequential I/O"
    echo "   fio --name=seqwrite --ioengine=libaio --iodepth=1 --rw=write --bs=128k --direct=1 --size=1G"
    echo ""
    echo "   # Mixed I/O"
    echo "   fio --name=mixed --ioengine=libaio --iodepth=32 --rw=randrw --bs=4k --direct=1 --size=1G"
    echo ""
    echo "For more information, see the storage documentation."
  '';
}
