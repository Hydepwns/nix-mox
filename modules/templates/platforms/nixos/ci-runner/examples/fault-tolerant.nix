{ config, pkgs, ... }:

{
  imports = [ ../src/ci-runner.nix ];

  services.ci-runner = {
    enable = true;
    maxParallelJobs = 4;
    retryAttempts = 5; # More retry attempts
    retryDelay = 10; # Longer retry delay
    logLevel = "debug"; # Detailed logging for debugging
    enableMetrics = true;
  };

  # Enhanced monitoring
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "process"
      "systemd"
      "cpu"
      "meminfo"
      "diskstats"
    ];
  };

  # Example fault-tolerant job definitions
  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "run-fault-tolerant-jobs" ''
      #!/bin/sh
      set -e

      # Function to add a job with retry wrapper
      add_job_with_retry() {
        local cmd="$1"
        local max_retries=5
        local retry_delay=10

        add_job "
          retries=0
          while [ \$retries -lt $max_retries ]; do
            if $cmd; then
              exit 0
            fi
            retries=\$((retries + 1))
            echo 'Job failed, attempt \$retries of $max_retries'
            sleep $retry_delay
          done
          exit 1
        "
      }

      # Add jobs with retry mechanism
      add_job_with_retry "echo 'Running critical job 1'"
      add_job_with_retry "echo 'Running critical job 2'"
      add_job_with_retry "echo 'Running critical job 3'"

      # Start the CI runner service
      systemctl start ci-runner
    '')
  ];
}
