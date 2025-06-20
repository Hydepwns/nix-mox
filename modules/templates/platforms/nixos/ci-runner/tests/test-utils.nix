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

  # Test job queue
  testJobQueue = { job, expectedResult }:
    let
      queueScript = pkgs.writeScript "test-queue.sh" ''
        #!/bin/sh
        set -e

        # Initialize queue
        queue_file="/tmp/test-queue"
        echo "$job" > "$queue_file"

        # Process job
        result=$(head -n 1 "$queue_file")
        if [ "$result" = "$expectedResult" ]; then
          exit 0
        else
          exit 1
        fi
      '';
    in
    pkgs.runCommand "test-queue" {} ''
      ${queueScript}
      touch $out
    '';

  # Test parallel execution
  testParallelExecution = { jobs, maxParallel }:
    let
      parallelScript = pkgs.writeScript "test-parallel.sh" ''
        #!/bin/sh
        set -e

        active_jobs=0
        max_jobs=${toString maxParallel}

        for job in ${toString jobs}; do
          if [ $active_jobs -lt $max_jobs ]; then
            active_jobs=$((active_jobs + 1))
            $job &
            job_pid=$!
            wait $job_pid
            active_jobs=$((active_jobs - 1))
          else
            wait -n
            active_jobs=$((active_jobs - 1))
            $job &
            job_pid=$!
            wait $job_pid
            active_jobs=$((active_jobs + 1))
          fi
        done
      '';
    in
    pkgs.runCommand "test-parallel" {} ''
      ${parallelScript}
      touch $out
    '';

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

  # Test logging
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
} 