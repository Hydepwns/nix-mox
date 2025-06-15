{ config, pkgs, lib, ... }:

let
  # Configuration options
  cfg = {
    enable = true;
    maxParallelJobs = 4;
    retryAttempts = 3;
    retryDelay = 5;
    logLevel = "info";
    enableMetrics = true;
  };

  # Helper functions
  logMessage = level: message: ''
    if [ "${toString cfg.enableLogging}" = "true" ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $message"
    fi
  '';

  # Retry mechanism
  retryOperation = operation: errorMsg: ''
    retries=0
    while [ $retries -lt ${toString cfg.retryAttempts} ]; do
      if $operation; then
        return 0
      fi
      retries=$((retries + 1))
      ${logMessage "WARN" "$errorMsg, attempt $retries of ${toString cfg.retryAttempts}"}
      sleep ${toString cfg.retryDelay}
    done
    ${logMessage "ERROR" "$errorMsg after ${toString cfg.retryAttempts} attempts"}
    return 1
  '';

  # Job queue management
  jobQueue = pkgs.writeScript "job-queue.sh" ''
    #!/bin/sh
    set -e

    # Initialize job queue
    queue_file="/tmp/ci-job-queue"
    touch "$queue_file"

    # Add job to queue
    add_job() {
      echo "$1" >> "$queue_file"
    }

    # Process next job
    process_next_job() {
      if [ -s "$queue_file" ]; then
        head -n 1 "$queue_file" > /tmp/current-job
        sed -i '1d' "$queue_file"
        cat /tmp/current-job
      fi
    }

    # Clean up
    cleanup() {
      rm -f "$queue_file" /tmp/current-job
    }
  '';

  # Parallel job executor
  parallelExecutor = pkgs.writeScript "parallel-executor.sh" ''
    #!/bin/sh
    set -e

    # Initialize parallel execution
    active_jobs=0
    max_jobs=${toString cfg.maxParallelJobs}

    # Execute job with parallel control
    execute_job() {
      if [ $active_jobs -lt $max_jobs ]; then
        active_jobs=$((active_jobs + 1))
        "$@" &
        job_pid=$!
        wait $job_pid
        active_jobs=$((active_jobs - 1))
      else
        wait -n
        active_jobs=$((active_jobs - 1))
        "$@" &
        job_pid=$!
        wait $job_pid
        active_jobs=$((active_jobs + 1))
      fi
    }
  '';
in
{
  options = {
    services.ci-runner = {
      enable = lib.mkEnableOption "CI Runner service";
      maxParallelJobs = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Maximum number of parallel jobs";
      };
      retryAttempts = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Number of retry attempts for failed jobs";
      };
      retryDelay = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Delay between retry attempts in seconds";
      };
      logLevel = lib.mkOption {
        type = lib.types.enum [ "debug" "info" "warn" "error" ];
        default = "info";
        description = "Logging level";
      };
      enableMetrics = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable metrics collection";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ci-runner = {
      description = "CI Runner Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "10s";
        ExecStart = "${pkgs.bash}/bin/bash ${parallelExecutor}";
      };
    };

    # Add monitoring if enabled
    services.prometheus.exporters.node = lib.mkIf cfg.enableMetrics {
      enable = true;
      enabledCollectors = [
        "process"
        "systemd"
      ];
    };

    # Add metrics to Prometheus
    services.prometheus.scrapeConfigs = lib.mkIf cfg.enableMetrics [
      {
        job_name = "ci-runner";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
      }
    ];

    # Add required packages
    environment.systemPackages = with pkgs; [
      bash
      coreutils
      gnutar
      gzip
    ];
  };
} 