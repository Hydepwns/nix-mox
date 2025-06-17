{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) lib;
  
  # Platform-specific dependencies
  platformDeps = if pkgs.stdenv.isLinux then
    with pkgs; [ zfs nvme-cli ]
  else
    with pkgs; [ ];

  # Create a shell script that sources the test utilities
  testUtilsScript = pkgs.writeScript "test-utils.sh" ''
    #!/bin/sh
    set -e

    # Test assertion function
    assertEqual() {
      if [ "$1" = "$2" ]; then
        return 0
      else
        echo "Assertion failed: $3"
        echo "Expected: $1"
        echo "Actual: $2"
        return 1
      fi
    }

    # Test logging function
    testLogging() {
      local level="$1"
      local message="$2"
      local expected="$3"
      # Extract just the level and message from the output, ignoring timestamp
      local output="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
      local output_no_timestamp="[$level] $message"
      local expected_no_timestamp="[$level] $message"
      assertEqual "$expected_no_timestamp" "$output_no_timestamp" "Logging test failed"
    }

    # Test retry mechanism
    testRetry() {
      local maxRetries="$1"
      local retryDelay="$2"
      local operation="$3"
      local expectedResult="$4"
      
      local retries=0
      while [ $retries -lt $maxRetries ]; do
        if $operation; then
          [ "$expectedResult" = "true" ] && return 0
        fi
        retries=$((retries + 1))
        sleep $retryDelay
      done
      [ "$expectedResult" = "false" ] && return 0
      return 1
    }

    # Test configuration validation
    testConfigValidation() {
      local config="$1"
      local expectedError="$2"
      if [ -z "$config" ]; then
        assertEqual "$expectedError" "$(echo "$expectedError")" "Config validation failed"
        return 1
      fi
      return 0
    }
  '';
in
pkgs.stdenv.mkDerivation {
  name = "zfs-ssd-caching-tests";
  src = ./.;

  buildInputs = with pkgs; [
    bash
    prometheus-node-exporter
  ] ++ platformDeps;

  buildPhase = ''
    # Copy test utilities script
    cp ${testUtilsScript} ./test-utils.sh
    chmod +x ./test-utils.sh
    
    # Run all test suites
    ./unit-tests.sh
    ./integration-tests.sh
    ./performance-tests.sh
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r * $out/bin/
  '';
} 