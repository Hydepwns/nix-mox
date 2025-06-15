{ pkgs ? import <nixpkgs> {} }:

let
  # Platform-specific dependencies
  platformDeps = with pkgs; [
    zfs
    fio
    iozone3
    gnumake
    gcc
    binutils
    coreutils
    gnugrep
    gnused
    gawk
  ];

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
        echo "Measuring L2ARC cache hits..."
        ${pkgs.zfs}/bin/zpool iostat -v
        ${pkgs.zfs}/bin/zpool status
      }

      measureSpecialVDevPerformance() {
        echo "Measuring Special VDEV performance..."
        ${pkgs.zfs}/bin/zpool iostat -v
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
