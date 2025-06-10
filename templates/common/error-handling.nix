{ config, pkgs, lib, ... }:
let
  # Common error handling configuration
  cfg = {
    enableLogging = true;
    logLevel = "info";  # debug, info, warn, error
    maxRetries = 3;
    retryDelay = 5;
    logFile = "/var/log/template-errors.log";
  };

  # Standardized logging function
  logMessage = level: message: ''
    if [ "${toString cfg.enableLogging}" = "true" ]; then
      timestamp=$(date '+%Y-%m-%d %H:%M:%S')
      echo "[$timestamp] [${level}] $message"
      if [ "${toString cfg.enableLogging}" = "true" ]; then
        echo "[$timestamp] [${level}] $message" >> ${cfg.logFile}
      fi
    fi
  '';

  # Standardized error handling function
  handleError = errorCode: errorMessage: ''
    ${logMessage "ERROR" "Error $errorCode: $errorMessage"}
    case $errorCode in
      1) # Configuration error
        ${logMessage "ERROR" "Configuration validation failed"}
        exit 1
        ;;
      2) # Resource not found
        ${logMessage "ERROR" "Required resource not found"}
        exit 2
        ;;
      3) # Permission denied
        ${logMessage "ERROR" "Permission denied"}
        exit 3
        ;;
      4) # Operation timeout
        ${logMessage "ERROR" "Operation timed out"}
        exit 4
        ;;
      5) # Resource in use
        ${logMessage "ERROR" "Resource is already in use"}
        exit 5
        ;;
      *) # Unknown error
        ${logMessage "ERROR" "Unknown error occurred"}
        exit 255
        ;;
    esac
  '';

  # Standardized retry mechanism
  retryOperation = operation: errorMsg: maxRetries: delay: ''
    retries=0
    while [ $retries -lt $maxRetries ]; do
      if $operation; then
        return 0
      fi
      retries=$((retries + 1))
      error_output=$($operation 2>&1)
      ${logMessage "WARN" "$errorMsg, attempt $retries of $maxRetries. Error: $error_output"}
      sleep $delay
    done
    ${logMessage "ERROR" "$errorMsg after $maxRetries attempts. Last error: $error_output"}
    return 1
  '';

  # Standardized validation function
  validateConfig = validations: ''
    for validation in "${validations}"; do
      if ! eval "$validation"; then
        ${handleError "1" "Configuration validation failed: $validation"}
      fi
    done
  '';

  # Standardized health check function
  checkHealth = checkCmd: errorMsg: ''
    if ! $checkCmd; then
      ${logMessage "ERROR" "$errorMsg"}
      return 1
    fi
    return 0
  '';

  # Standardized cleanup function
  cleanup = cleanupCmd: ''
    if [ -n "$cleanupCmd" ]; then
      ${logMessage "INFO" "Running cleanup operation"}
      if ! $cleanupCmd; then
        ${logMessage "WARN" "Cleanup operation failed"}
      fi
    fi
  '';

  # Standardized timeout function
  withTimeout = timeout: cmd: ''
    (
      $cmd &
      cmd_pid=$!
      (
        sleep $timeout
        kill $cmd_pid 2>/dev/null
        ${logMessage "ERROR" "Operation timed out after $timeout seconds"}
        exit 4
      ) &
      timeout_pid=$!
      wait $cmd_pid
      kill $timeout_pid 2>/dev/null
    )
  '';

  # Standardized resource locking
  withLock = lockFile: cmd: ''
    (
      flock -n 9 || ${handleError "5" "Resource is locked"}
      $cmd
    ) 9>$lockFile
  '';

  # Standardized error recovery
  recoverFromError = errorCode: recoveryCmd: ''
    case $errorCode in
      1) # Configuration error
        ${logMessage "INFO" "Attempting to recover from configuration error"}
        $recoveryCmd
        ;;
      2) # Resource not found
        ${logMessage "INFO" "Attempting to recover from missing resource"}
        $recoveryCmd
        ;;
      3) # Permission denied
        ${logMessage "INFO" "Attempting to recover from permission error"}
        $recoveryCmd
        ;;
      4) # Operation timeout
        ${logMessage "INFO" "Attempting to recover from timeout"}
        $recoveryCmd
        ;;
      5) # Resource in use
        ${logMessage "INFO" "Attempting to recover from resource conflict"}
        $recoveryCmd
        ;;
      *) # Unknown error
        ${logMessage "INFO" "Attempting to recover from unknown error"}
        $recoveryCmd
        ;;
    esac
  '';
in
{
  options = {
    template.errorHandling = {
      enable = lib.mkEnableOption "Enable standardized error handling";
      logLevel = lib.mkOption {
        type = lib.types.enum [ "debug" "info" "warn" "error" ];
        default = "info";
        description = "Logging level for error handling";
      };
      maxRetries = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Maximum number of retry attempts";
      };
      retryDelay = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Delay between retry attempts in seconds";
      };
      logFile = lib.mkOption {
        type = lib.types.path;
        default = "/var/log/template-errors.log";
        description = "Path to error log file";
      };
    };
  };

  config = lib.mkIf config.template.errorHandling.enable {
    environment.systemPackages = [
      (pkgs.writeScriptBin "template-error-handler" ''
        #!/bin/sh
        set -e

        # Source the error handling functions
        . ${pkgs.writeText "error-handling.sh" ''
          ${logMessage}
          ${handleError}
          ${retryOperation}
          ${validateConfig}
          ${checkHealth}
          ${cleanup}
          ${withTimeout}
          ${withLock}
          ${recoverFromError}
        ''}

        # Export functions for use in other scripts
        export -f logMessage
        export -f handleError
        export -f retryOperation
        export -f validateConfig
        export -f checkHealth
        export -f cleanup
        export -f withTimeout
        export -f withLock
        export -f recoverFromError
      '')
    ];
  };
} 