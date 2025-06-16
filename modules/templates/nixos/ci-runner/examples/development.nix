{ config, pkgs, ... }:

{
  imports = [ ../src/ci-runner.nix ];

  services.ci-runner = {
    enable = true;
    maxParallelJobs = 2;  # Lower parallel jobs for development
    retryAttempts = 2;
    retryDelay = 5;
    logLevel = "debug";   # Detailed logging for development
    enableMetrics = true;
  };

  # Development tools
  environment.systemPackages = with pkgs; [
    # Debugging tools
    strace
    lsof
    htop
    tmux
    vim

    # Development job runner
    (pkgs.writeScriptBin "run-dev-jobs" ''
      #!/bin/sh
      set -e

      # Function to add a development job with debugging
      add_dev_job() {
        local cmd="$1"
        local job_name="$2"

        add_job "
          echo 'Starting development job: $job_name'
          echo 'Command: $cmd'
          
          # Run with strace for debugging
          strace -f -o /tmp/strace-\$\$.log $cmd
          
          # Check exit status
          if [ \$? -eq 0 ]; then
            echo 'Job completed successfully'
            exit 0
          else
            echo 'Job failed, check /tmp/strace-\$\$.log for details'
            exit 1
          fi
        "
      }

      # Add development jobs
      add_dev_job "echo 'Running development job 1'" "dev-job-1"
      add_dev_job "echo 'Running development job 2'" "dev-job-2"

      # Start the CI runner service
      systemctl start ci-runner
    '')
  ];

  # Development-specific monitoring
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "process"
      "systemd"
      "cpu"
      "meminfo"
      "diskstats"
      "filefd"
      "netstat"
    ];
  };
} 