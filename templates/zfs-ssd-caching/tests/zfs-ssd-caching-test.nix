{ pkgs, lib, ... }:
let
  # Test configuration
  testConfig = {
    poolName = "testpool";
    devicePattern = "/dev/test-nvme*n1";
    cacheType = "l2arc";
    cacheMode = "mirror";
    enableLogging = true;
    maxRetries = 2;
    retryDelay = 1;
  };

  # Mock ZFS commands
  mockZpool = pkgs.writeScriptBin "zpool" ''
    #!/bin/sh
    case "$1" in
      "list")
        if [ "$2" = "${testConfig.poolName}" ]; then
          echo "NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT"
          echo "${testConfig.poolName}  100G   50G    50G        -         -     0%    50%  1.00x  ONLINE  -"
          exit 0
        else
          exit 1
        fi
        ;;
      "status")
        if [ "$2" = "${testConfig.poolName}" ]; then
          echo "  pool: ${testConfig.poolName}"
          echo " state: ONLINE"
          echo "  scan: scrub repaired 0B in 00:00:00 with 0 errors"
          echo "config:"
          echo "        NAME        STATE     READ WRITE CKSUM"
          echo "        ${testConfig.poolName}  ONLINE       0     0     0"
          exit 0
        else
          exit 1
        fi
        ;;
      "add")
        if [ "$2" = "${testConfig.poolName}" ]; then
          echo "Added device $4 to pool ${testConfig.poolName}"
          exit 0
        else
          exit 1
        fi
        ;;
      "set")
        if [ "$2" = "${testConfig.poolName}" ]; then
          echo "Set property $3 to $4 for pool ${testConfig.poolName}"
          exit 0
        else
          exit 1
        fi
        ;;
      *)
        echo "Unknown command: $1"
        exit 1
        ;;
    esac
  '';

  # Mock smartctl command
  mockSmartctl = pkgs.writeScriptBin "smartctl" ''
    #!/bin/sh
    if [ "$1" = "-H" ]; then
      echo "SMART overall-health self-assessment test result: PASSED"
      exit 0
    else
      echo "Unknown command: $1"
      exit 1
    fi
  '';

  # Mock blockdev command
  mockBlockdev = pkgs.writeScriptBin "blockdev" ''
    #!/bin/sh
    if [ "$1" = "--getsize64" ]; then
      echo "100000000000"  # 100GB in bytes
      exit 0
    else
      echo "Unknown command: $1"
      exit 1
    fi
  '';

  # Test environment
  testEnv = pkgs.buildEnv {
    name = "zfs-ssd-caching-test-env";
    paths = [
      mockZpool
      mockSmartctl
      mockBlockdev
    ];
  };
in
{
  name = "zfs-ssd-caching-test";

  nodes = {
    machine = { config, pkgs, ... }: {
      environment.systemPackages = [ testEnv ];
      imports = [ ./zfs-ssd-caching.nix ];
      services.zfs-ssd-caching = testConfig;
    };
  };

  testScript = ''
    start_all()

    # Test 1: Basic pool detection
    machine.succeed("zpool list ${testConfig.poolName}")

    # Test 2: Device health check
    machine.succeed("smartctl -H /dev/test-nvme0n1")

    # Test 3: Cache size calculation
    machine.succeed("blockdev --getsize64 /dev/test-nvme0n1")

    # Test 4: Service start
    machine.succeed("systemctl start zfs-ssd-caching")

    # Test 5: Service status
    machine.succeed("systemctl status zfs-ssd-caching")

    # Test 6: Log verification
    machine.succeed("grep 'Starting ZFS SSD caching configuration' /var/log/zfs-ssd-caching.log")

    # Test 7: Pool health check
    machine.succeed("zpool status ${testConfig.poolName} | grep 'state: ONLINE'")

    # Test 8: Cache addition
    machine.succeed("zpool add ${testConfig.poolName} cache /dev/test-nvme0n1")

    # Test 9: Auto-scrub configuration
    machine.succeed("zpool set autoscrub=on ${testConfig.poolName}")

    # Test 10: Auto-trim configuration
    machine.succeed("zpool set autotrim=on ${testConfig.poolName}")
  '';
} 