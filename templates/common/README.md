# Common Template Components

This directory contains common components that can be used across all templates to ensure consistency and reduce code duplication.

## Error Handling Module

The error handling module provides standardized error handling, logging, and recovery mechanisms for all templates.

### Features

- **Standardized Logging**
  - Multiple log levels (debug, info, warn, error)
  - Timestamp-based logging
  - File and console output
  - Configurable log file location

- **Error Handling**
  - Standardized error codes
  - Detailed error messages
  - Error categorization
  - Automatic error logging

- **Retry Mechanism**
  - Configurable retry attempts
  - Adjustable retry delays
  - Detailed retry logging
  - Operation-specific retry policies

- **Health Checks**
  - Resource health validation
  - Service status checking
  - Dependency verification
  - Automatic health reporting

- **Resource Management**
  - Resource locking
  - Cleanup operations
  - Timeout handling
  - Resource conflict resolution

- **Error Recovery**
  - Automatic recovery attempts
  - Error-specific recovery strategies
  - Recovery logging
  - Fallback mechanisms

### Usage

1. Import the module in your template:

```nix
{ config, pkgs, lib, ... }:
{
  imports = [ ./common/error-handling.nix ];
  
  template.errorHandling = {
    enable = true;
    logLevel = "info";
    maxRetries = 3;
    retryDelay = 5;
    logFile = "/var/log/my-template-errors.log";
  };
}
```

2. Use the error handling functions in your scripts:

```bash
#!/bin/sh
set -e

# Source the error handling functions
. template-error-handler

# Log a message
logMessage "INFO" "Starting operation"

# Validate configuration
validateConfig "test -f config.json" "test -d data"

# Retry an operation
retryOperation "my_command" "Failed to execute command" 3 5

# Check health
checkHealth "service_is_running" "Service is not running"

# Use timeout
withTimeout 30 "long_running_command"

# Use resource locking
withLock "/var/lock/my-lock" "critical_operation"

# Handle errors
if ! some_operation; then
  handleError 1 "Operation failed"
fi

# Cleanup
cleanup "cleanup_command"

# Recover from error
recoverFromError 1 "recovery_command"
```

### Error Codes

1. **Configuration Error (1)**
   - Invalid configuration
   - Missing required parameters
   - Invalid parameter values

2. **Resource Not Found (2)**
   - Missing files
   - Missing directories
   - Missing services
   - Missing dependencies

3. **Permission Denied (3)**
   - File permissions
   - Directory permissions
   - Service permissions
   - User permissions

4. **Operation Timeout (4)**
   - Command timeout
   - Service timeout
   - Network timeout
   - Resource timeout

5. **Resource In Use (5)**
   - File in use
   - Port in use
   - Service in use
   - Lock conflict

### Best Practices

1. **Logging**
   - Use appropriate log levels
   - Include relevant context
   - Log all errors
   - Use consistent formatting

2. **Error Handling**
   - Use specific error codes
   - Provide detailed messages
   - Handle all error cases
   - Implement recovery strategies

3. **Retries**
   - Set reasonable retry limits
   - Use exponential backoff
   - Log retry attempts
   - Consider operation type

4. **Health Checks**
   - Check all dependencies
   - Verify resource availability
   - Monitor service health
   - Report health status

5. **Resource Management**
   - Always clean up resources
   - Use appropriate timeouts
   - Implement proper locking
   - Handle conflicts gracefully

### Integration

The error handling module can be integrated with:

- Monitoring systems
- Log aggregation
- Alert systems
- CI/CD pipelines
- Testing frameworks

### Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

### License

This module is licensed under the MIT License.
