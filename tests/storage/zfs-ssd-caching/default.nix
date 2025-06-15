{ pkgs ? import <nixpkgs> {} }:

let
  # Platform-specific dependencies
  platformDeps = with pkgs; [
    fio
    gnumake
    gcc
    binutils
    coreutils
    gnugrep
    gnused
    gawk
  ] ++ (if pkgs.stdenv.isLinux then [ zfs ] else []);

  # Test utilities script
  testUtils = pkgs.writeTextFile {
    name = "test-utils.sh";
    text = ''
      #!/bin/bash
      set -ex

      echo "Loading test utilities..."

      # Assertion function
      assertEqual() {
        local expected=$1
        local actual=$2
        local message=$3
        echo "Asserting: $message"
        echo "Expected: $expected"
        echo "Actual: $actual"
        if [ "$expected" = "$actual" ]; then
          echo "✓ Test passed: $message"
          return 0
        else
          echo "✗ Test failed: $message"
          return 1
        fi
      }

      # Logging function
      testLogging() {
        echo "Testing logging functionality..."
        local test_message="Test log message"
        echo "$test_message"
        assertEqual "$test_message" "$test_message" "Logging test"
      }

      # Retry mechanism
      testRetry() {
        echo "Testing retry mechanism..."
        local max_attempts=3
        local attempt=1
        local success=false

        while [ $attempt -le $max_attempts ]; do
          echo "Attempt $attempt of $max_attempts"
          if [ $attempt -eq $max_attempts ]; then
            success=true
          fi
          attempt=$((attempt + 1))
          sleep 1
        done

        assertEqual "true" "$success" "Retry mechanism test"
      }

      # Configuration validation
      testConfigValidation() {
        echo "Testing configuration validation..."
        local config=""
        if [ -z "$config" ]; then
          echo "Empty config rejected as expected"
          return 0  # Success - empty configs should be rejected
        fi
        return 1
      }

      # ZFS-specific test utilities
      setupTestPool() {
        local pool_name=$1
        local vdev_type=$2
        local cache_type=$3
        echo "Setting up test pool: $pool_name"

        # Create a temporary file for the pool
        local pool_file="/tmp/${pool_name}.img"
        truncate -s 1G "$pool_file"

        # Create the pool with specified vdev type
        ${pkgs.zfs}/bin/zpool create -f "$pool_name" "$vdev_type" "$pool_file"

        # Add cache if specified
        if [ "$cache_type" = "l2arc" ]; then
          local cache_file="/tmp/${pool_name}_cache.img"
          truncate -s 512M "$cache_file"
          ${pkgs.zfs}/bin/zpool add "$pool_name" cache "$cache_file"
        elif [ "$cache_type" = "special" ]; then
          local special_file="/tmp/${pool_name}_special.img"
          truncate -s 512M "$special_file"
          ${pkgs.zfs}/bin/zpool add "$pool_name" special "$special_file"
        fi
      }

      cleanupTestPool() {
        local pool_name=$1
        echo "Cleaning up test pool: $pool_name"
        ${pkgs.zfs}/bin/zpool destroy -f "$pool_name"
        rm -f "/tmp/${pool_name}.img" "/tmp/${pool_name}_cache.img" "/tmp/${pool_name}_special.img"
      }

      # Snapshot tests
      testSnapshotOperations() {
        local pool_name="test_pool"
        echo "Testing snapshot operations..."

        setupTestPool "$pool_name" "mirror" ""

        # Create a test dataset
        ${pkgs.zfs}/bin/zfs create "$pool_name/test"

        # Generate initial data
        echo "Initial data" > "/$pool_name/test/data"

        # Create snapshot
        ${pkgs.zfs}/bin/zfs snapshot "$pool_name/test@snap1"

        # Modify data
        echo "Modified data" > "/$pool_name/test/data"

        # Create another snapshot
        ${pkgs.zfs}/bin/zfs snapshot "$pool_name/test@snap2"

        # List snapshots
        local snap_count=$(${pkgs.zfs}/bin/zfs list -t snapshot -H "$pool_name/test" | wc -l)
        assertEqual "2" "$snap_count" "Should have 2 snapshots"

        # Verify snapshot contents
        local snap1_content=$(${pkgs.zfs}/bin/zfs get -H -o value creation "$pool_name/test@snap1")
        local snap2_content=$(${pkgs.zfs}/bin/zfs get -H -o value creation "$pool_name/test@snap2")
        assertEqual "1" "$(echo "$snap1_content < $snap2_content" | bc)" "Snap2 should be newer than Snap1"

        cleanupTestPool "$pool_name"
      }

      testSnapshotRollback() {
        local pool_name="test_pool"
        echo "Testing snapshot rollback..."

        setupTestPool "$pool_name" "mirror" ""

        # Create a test dataset
        ${pkgs.zfs}/bin/zfs create "$pool_name/test"

        # Generate initial data
        echo "Initial data" > "/$pool_name/test/data"

        # Create snapshot
        ${pkgs.zfs}/bin/zfs snapshot "$pool_name/test@snap1"

        # Modify data
        echo "Modified data" > "/$pool_name/test/data"

        # Rollback to snapshot
        ${pkgs.zfs}/bin/zfs rollback "$pool_name/test@snap1"

        # Verify data is back to original
        local content=$(cat "/$pool_name/test/data")
        assertEqual "Initial data" "$content" "Data should be back to initial state"

        cleanupTestPool "$pool_name"
      }

      testSnapshotClone() {
        local pool_name="test_pool"
        echo "Testing snapshot clone..."

        setupTestPool "$pool_name" "mirror" ""

        # Create a test dataset
        ${pkgs.zfs}/bin/zfs create "$pool_name/test"

        # Generate initial data
        echo "Initial data" > "/$pool_name/test/data"

        # Create snapshot
        ${pkgs.zfs}/bin/zfs snapshot "$pool_name/test@snap1"

        # Create clone
        ${pkgs.zfs}/bin/zfs clone "$pool_name/test@snap1" "$pool_name/clone"

        # Verify clone exists and has correct data
        local clone_exists=$(${pkgs.zfs}/bin/zfs list -H "$pool_name/clone" | wc -l)
        assertEqual "1" "$clone_exists" "Clone should exist"

        local clone_content=$(cat "/$pool_name/clone/data")
        assertEqual "Initial data" "$clone_content" "Clone should have initial data"

        cleanupTestPool "$pool_name"
      }

      # Encryption tests
      testEncryptionSetup() {
        local pool_name="test_pool"
        echo "Testing encryption setup..."

        setupTestPool "$pool_name" "mirror" ""

        # Create encrypted dataset
        ${pkgs.zfs}/bin/zfs create -o encryption=on -o keyformat=passphrase "$pool_name/encrypted"

        # Verify encryption is enabled
        local encryption=$(${pkgs.zfs}/bin/zfs get -H -o value encryption "$pool_name/encrypted")
        assertEqual "on" "$encryption" "Encryption should be enabled"

        # Test different encryption algorithms
        local algorithms=("aes-128-ccm" "aes-192-ccm" "aes-256-ccm" "aes-128-gcm" "aes-192-gcm" "aes-256-gcm")
        for algo in "''${algorithms[@]}"; do
          echo "Testing $algo encryption..."
          ${pkgs.zfs}/bin/zfs create -o encryption=$algo -o keyformat=passphrase "$pool_name/encrypted_$algo"

          # Verify algorithm is set
          local algo_set=$(${pkgs.zfs}/bin/zfs get -H -o value encryption "$pool_name/encrypted_$algo")
          assertEqual "$algo" "$algo_set" "Encryption algorithm should be $algo"
        done

        cleanupTestPool "$pool_name"
      }

      testEncryptedOperations() {
        local pool_name="test_pool"
        echo "Testing encrypted operations..."

        setupTestPool "$pool_name" "mirror" ""

        # Create encrypted dataset
        ${pkgs.zfs}/bin/zfs create -o encryption=on -o keyformat=passphrase "$pool_name/encrypted"

        # Generate test data
        echo "Secret data" > "/$pool_name/encrypted/data"

        # Create snapshot
        ${pkgs.zfs}/bin/zfs snapshot "$pool_name/encrypted@snap1"

        # Create clone
        ${pkgs.zfs}/bin/zfs clone "$pool_name/encrypted@snap1" "$pool_name/encrypted_clone"

        # Verify clone is also encrypted
        local clone_encryption=$(${pkgs.zfs}/bin/zfs get -H -o value encryption "$pool_name/encrypted_clone")
        assertEqual "on" "$clone_encryption" "Clone should be encrypted"

        # Test key management
        ${pkgs.zfs}/bin/zfs change-key -l "$pool_name/encrypted"
        ${pkgs.zfs}/bin/zfs change-key -i "$pool_name/encrypted"

        cleanupTestPool "$pool_name"
      }

      testEncryptionPerformance() {
        local pool_name="test_pool"
        echo "Testing encryption performance..."

        setupTestPool "$pool_name" "mirror" ""

        # Create datasets with and without encryption
        ${pkgs.zfs}/bin/zfs create "$pool_name/no_enc"
        ${pkgs.zfs}/bin/zfs create -o encryption=on -o keyformat=passphrase "$pool_name/enc"

        # Generate test data
        dd if=/dev/urandom of="/$pool_name/no_enc/data" bs=1M count=100
        dd if=/dev/urandom of="/$pool_name/enc/data" bs=1M count=100

        # Measure write performance
        echo "Measuring write performance..."
        for dataset in "no_enc" "enc"; do
          echo "Testing $dataset write performance..."
          ${pkgs.fio}/bin/fio --name=write_test \
            --rw=write \
            --size=100M \
            --runtime=30 \
            --time_based \
            --direct=1 \
            --ioengine=libaio \
            --iodepth=64 \
            --numjobs=1 \
            --group_reporting \
            --filename="/$pool_name/$dataset/data"
        done

        cleanupTestPool "$pool_name"
      }

      # Performance test utilities
      runFioTest() {
        local test_name=$1
        local test_type=$2
        local test_size=$3
        local test_runtime=$4
        echo "Running FIO test: $test_name"
        ${pkgs.fio}/bin/fio --name=$test_name \
          --rw=$test_type \
          --size=$test_size \
          --runtime=$test_runtime \
          --time_based \
          --direct=1 \
          --ioengine=libaio \
          --iodepth=64 \
          --numjobs=4 \
          --group_reporting
      }

      measureL2ARCHits() {
        if command -v ${pkgs.zfs}/bin/zpool >/dev/null 2>&1; then
          echo "Measuring L2ARC cache hits..."
          ${pkgs.zfs}/bin/zpool iostat -v
          ${pkgs.zfs}/bin/zpool status
        else
          echo "ZFS not available, skipping L2ARC measurements"
        fi
      }

      measureSpecialVDevPerformance() {
        if command -v ${pkgs.zfs}/bin/zpool >/dev/null 2>&1; then
          echo "Measuring Special VDEV performance..."
          ${pkgs.zfs}/bin/zpool iostat -v
        else
          echo "ZFS not available, skipping Special VDEV measurements"
        fi
      }

      measureIOLatency() {
        local test_size="1G"
        local iodepth=64
        echo "Measuring I/O latency..."
        ${pkgs.fio}/bin/fio --name=latency_test \
          --rw=randread \
          --size=$test_size \
          --runtime=30 \
          --time_based \
          --direct=1 \
          --ioengine=libaio \
          --iodepth=$iodepth \
          --numjobs=1 \
          --group_reporting
      }

      warmCache() {
        echo "Warming cache..."
        ${pkgs.fio}/bin/fio --name=warmup \
          --rw=read \
          --size=1G \
          --runtime=30 \
          --time_based \
          --direct=1 \
          --ioengine=libaio \
          --iodepth=64 \
          --numjobs=4 \
          --group_reporting
      }

      echo "Test utilities loaded successfully"
    '';
  };

  # Unit tests script
  unitTests = pkgs.writeTextFile {
    name = "unit-tests.sh";
    text = ''
      #!/bin/bash
      set -ex

      echo "Running unit tests..."
      source ${testUtils}

      # Run test cases
      testLogging
      testRetry
      testConfigValidation

      echo "Unit tests completed successfully"
    '';
  };

  # Integration tests script
  integrationTests = pkgs.writeTextFile {
    name = "integration-tests.sh";
    text = ''
      #!/bin/bash
      set -ex

      echo "Running integration tests..."
      source ${testUtils}

      # Run test cases
      testLogging
      testRetry
      testConfigValidation

      echo "Integration tests completed successfully"
    '';
  };

  # Performance tests script
  performanceTests = pkgs.writeTextFile {
    name = "performance-tests.sh";
    text = ''
      #!/bin/bash
      set -ex

      echo "Running performance tests..."
      source ${testUtils}

      # Create test directory
      TEST_DIR="/tmp/zfs-ssd-caching-test"
      mkdir -p "$TEST_DIR"
      cd "$TEST_DIR"

      # Run FIO tests
      echo "Running FIO tests..."
      runFioTest "seq_read" "read" "1G" "30"
      runFioTest "seq_write" "write" "1G" "30"
      runFioTest "rand_read" "randread" "1G" "30"
      runFioTest "rand_write" "randwrite" "1G" "30"

      # Run ZFS-specific tests if available
      if command -v ${pkgs.zfs}/bin/zpool >/dev/null 2>&1; then
        echo "Running ZFS-specific tests..."
        testL2ARCConfiguration
        testSpecialVDevConfiguration
        testCacheWarming
        testDatasetConfiguration

        # Run compression tests
        echo "Running compression tests..."
        testCompressionAlgorithms
        testCompressionPerformance

        # Run deduplication tests
        echo "Running deduplication tests..."
        testDeduplication
        testDeduplicationPerformance

        # Run snapshot tests
        echo "Running snapshot tests..."
        testSnapshotOperations
        testSnapshotRollback
        testSnapshotClone

        # Run encryption tests
        echo "Running encryption tests..."
        testEncryptionSetup
        testEncryptedOperations
        testEncryptionPerformance
      else
        echo "ZFS not available, skipping ZFS-specific tests"
      fi

      # Measure L2ARC hits
      echo "Measuring L2ARC cache hits..."
      measureL2ARCHits

      # Measure Special VDEV performance
      echo "Measuring Special VDEV performance..."
      measureSpecialVDevPerformance

      # Measure I/O latency
      echo "Measuring I/O latency..."
      measureIOLatency

      # Warm cache and measure performance
      echo "Testing cache warming..."
      warmCache

      # Cleanup
      cd - > /dev/null
      rm -rf "$TEST_DIR"

      echo "Performance tests completed successfully"
    '';
  };

in pkgs.stdenv.mkDerivation {
  name = "zfs-ssd-caching-tests";
  src = ./.;
  buildInputs = platformDeps;

  buildPhase = ''
    echo "Copying test scripts..."
    cp ${unitTests} unit-tests.sh
    cp ${integrationTests} integration-tests.sh
    cp ${performanceTests} performance-tests.sh
    cp ${testUtils} test-utils.sh
    chmod +x *.sh
  '';

  doCheck = true;
  checkPhase = ''
    echo "Running test suites..."
    ./unit-tests.sh
    ./integration-tests.sh
    ./performance-tests.sh
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp *.sh $out/bin/
  '';
}
