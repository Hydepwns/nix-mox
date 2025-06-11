{ pkgs }:

let
  inherit (pkgs) lib;
in
{
  # Test assertion function
  assertEqual = expected: actual: message:
    if expected == actual then
      true
    else
      throw "Assertion failed: ${message}\nExpected: ${toString expected}\nActual: ${toString actual}";

  # Test retry mechanism
  testRetry = { maxRetries, retryDelay, operation, expectedResult }:
    let
      retryScript = pkgs.writeScript "test-retry.sh" ''
        #!/bin/sh
        set -e

        retries=0
        while [ $retries -lt ${toString maxRetries} ]; do
          if ${operation}; then
            exit 0
          fi
          retries=$((retries + 1))
          sleep ${toString retryDelay}
        done
        exit 1
      '';
    in
    pkgs.runCommand "test-retry" {} ''
      ${retryScript}
      touch $out
    '';

  # Test logging function
  testLogging = { level, message, expectedOutput }:
    let
      logScript = pkgs.writeScript "test-logging.sh" ''
        #!/bin/sh
        set -e

        logMessage() {
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2"
        }

        output=$(logMessage "${level}" "${message}")
        if [ "$output" = "${expectedOutput}" ]; then
          exit 0
        else
          exit 1
        fi
      '';
    in
    pkgs.runCommand "test-logging" {} ''
      ${logScript}
      touch $out
    '';

  # Test configuration validation
  testConfigValidation = { config, expectedError }:
    let
      validationScript = pkgs.writeScript "test-config.sh" ''
        #!/bin/sh
        set -e

        validateConfig() {
          if [ -z "$1" ]; then
            echo "${expectedError}"
            exit 1
          fi
          exit 0
        }

        validateConfig "${config}"
      '';
    in
    pkgs.runCommand "test-config" {} ''
      ${validationScript}
      touch $out
    '';

  # Common test patterns
  runUnitTests = { testScript, dependencies ? [] }:
    pkgs.runCommand "unit-tests" { buildInputs = dependencies; } ''
      ${testScript}
      touch $out
    '';

  runIntegrationTests = { testScript, dependencies ? [] }:
    pkgs.runCommand "integration-tests" { buildInputs = dependencies; } ''
      ${testScript}
      touch $out
    '';

  runPerformanceTests = { testScript, dependencies ? [] }:
    pkgs.runCommand "performance-tests" { buildInputs = dependencies; } ''
      ${testScript}
      touch $out
    '';
} 