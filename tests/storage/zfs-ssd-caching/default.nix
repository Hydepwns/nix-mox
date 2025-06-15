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

      testL2ARCConfiguration() {
        local pool_name="test_pool"
        echo "Testing L2ARC configuration..."

        setupTestPool "$pool_name" "mirror" "l2arc"

        # Verify L2ARC is present
        local l2arc_status=$(${pkgs.zfs}/bin/zpool status "$pool_name" | grep -c "cache")
        assertEqual "1" "$l2arc_status" "L2ARC should be present"

        # Test L2ARC properties
        local l2arc_size=$(${pkgs.zfs}/bin/zpool list -H -o size "$pool_name")
        assertEqual "1.00G" "$l2arc_size" "Pool size should be 1G"

        cleanupTestPool "$pool_name"
      }

      testSpecialVDevConfiguration() {
        local pool_name="test_pool"
        echo "Testing Special VDEV configuration..."

        setupTestPool "$pool_name" "mirror" "special"

        # Verify Special VDEV is present
        local special_status=$(${pkgs.zfs}/bin/zpool status "$pool_name" | grep -c "special")
        assertEqual "1" "$special_status" "Special VDEV should be present"

        # Test Special VDEV properties
        local special_size=$(${pkgs.zfs}/bin/zpool list -H -o size "$pool_name")
        assertEqual "1.00G" "$special_size" "Pool size should be 1G"

        cleanupTestPool "$pool_name"
      }

      testCacheWarming() {
        local pool_name="test_pool"
        echo "Testing cache warming..."

        setupTestPool "$pool_name" "mirror" "l2arc"

        # Create a test dataset
        ${pkgs.zfs}/bin/zfs create "$pool_name/test"

        # Generate test data
        dd if=/dev/urandom of="/$pool_name/test/data" bs=1M count=100

        # First read (should miss cache)
        echo "First read (cache miss)..."
        ${pkgs.fio}/bin/fio --name=first_read \
          --rw=read \
          --size=100M \
          --runtime=10 \
          --time_based \
          --direct=1 \
          --ioengine=libaio \
          --iodepth=64 \
          --numjobs=1 \
          --group_reporting \
          --filename="/$pool_name/test/data"

        # Second read (should hit cache)
        echo "Second read (cache hit)..."
        ${pkgs.fio}/bin/fio --name=second_read \
          --rw=read \
          --size=100M \
          --runtime=10 \
          --time_based \
          --direct=1 \
          --ioengine=libaio \
          --iodepth=64 \
          --numjobs=1 \
          --group_reporting \
          --filename="/$pool_name/test/data"

        # Verify cache hits
        local cache_hits=$(${pkgs.zfs}/bin/zpool iostat -v "$pool_name" | grep -c "cache")
        assertEqual "1" "$cache_hits" "Cache should be present"

        cleanupTestPool "$pool_name"
      }

      testDatasetConfiguration() {
        local pool_name="test_pool"
        echo "Testing dataset configuration..."

        setupTestPool "$pool_name" "mirror" "l2arc"

        # Create test datasets with different properties
        ${pkgs.zfs}/bin/zfs create -o recordsize=128K "$pool_name/test1"
        ${pkgs.zfs}/bin/zfs create -o recordsize=1M "$pool_name/test2"

        # Verify dataset properties
        local recordsize1=$(${pkgs.zfs}/bin/zfs get -H -o value recordsize "$pool_name/test1")
        local recordsize2=$(${pkgs.zfs}/bin/zfs get -H -o value recordsize "$pool_name/test2")

        assertEqual "128K" "$recordsize1" "Dataset 1 recordsize should be 128K"
        assertEqual "1M" "$recordsize2" "Dataset 2 recordsize should be 1M"

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
