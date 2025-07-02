logMessage() {
  local level="$1"
  local message="$2"
  if [ "${enableLogging:-false}" = "true" ]; then
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
    echo "[$timestamp] [$level] $message" >> "@logFile@"
  fi
}

handleError() {
  local errorCode="$1"
  local errorMessage="$2"
  logMessage "ERROR" "Error $errorCode: $errorMessage"
  exit "$errorCode"
}
