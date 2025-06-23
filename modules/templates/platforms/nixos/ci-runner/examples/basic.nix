{ config, pkgs, ... }:

{
  imports = [ ../src/ci-runner.nix ];

  services.ci-runner = {
    enable = true;
    maxParallelJobs = 2;
    retryAttempts = 2;
    retryDelay = 3;
    logLevel = "info";
    enableMetrics = true;
  };

  # Example job definitions
  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "run-basic-jobs" ''
      #!/bin/sh
      set -e

      # Add jobs to queue
      add_job "echo 'Running test job 1'"
      add_job "echo 'Running test job 2'"
      add_job "echo 'Running test job 3'"

      # Start the CI runner service
      systemctl start ci-runner
    '')
  ];
}
