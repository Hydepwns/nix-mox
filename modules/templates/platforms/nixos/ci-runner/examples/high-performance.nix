{ config, pkgs, ... }:

{
  imports = [ ../src/ci-runner.nix ];

  services.ci-runner = {
    enable = true;
    maxParallelJobs = 8; # Higher parallel job limit
    retryAttempts = 3;
    retryDelay = 2; # Shorter retry delay
    logLevel = "debug"; # More detailed logging
    enableMetrics = true;
  };

  # System tuning for high performance
  boot.kernel.sysctl = {
    "kernel.sched_autogroup" = 0;
    "vm.swappiness" = 10;
  };

  # Example high-performance job definitions
  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "run-high-performance-jobs" ''
      #!/bin/sh
      set -e

      # Function to generate test jobs
      generate_jobs() {
        for i in $(seq 1 20); do
          add_job "echo 'Running high-performance job $i'"
        done
      }

      # Add jobs to queue
      generate_jobs

      # Start the CI runner service
      systemctl start ci-runner
    '')
  ];
}
