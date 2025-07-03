# CI Runner Template

This template provides a flexible and robust CI runner service with parallel execution support, error handling, and monitoring capabilities.

## Features

- Parallel job execution with configurable limits
- Automatic retry mechanism for failed jobs
- Comprehensive logging system
- Job queue management
- Prometheus metrics integration
- Systemd service integration

## Usage

1. Import the module into your NixOS configuration:

   ```nix
   imports = [ ./src/ci-runner.nix ];
   ```

2. Configure options (optional):

   ```nix
   {
     services.ci-runner = {
       enable = true;
       maxParallelJobs = 4;
       retryAttempts = 3;
       retryDelay = 5;
       logLevel = "info";
       enableMetrics = true;
     };
   }
   ```

## Configuration Options

### Basic Options

- `enable`: Enable/disable the CI runner service
- `maxParallelJobs`: Maximum number of parallel jobs (default: 4)
- `retryAttempts`: Number of retry attempts for failed jobs (default: 3)
- `retryDelay`: Delay between retry attempts in seconds (default: 5)
- `logLevel`: Logging level (debug, info, warn, error)
- `enableMetrics`: Enable Prometheus metrics collection

## Job Management

### Adding Jobs

Jobs can be added to the queue using the job queue management script:

```bash
add_job "your-command-here"
```

### Processing Jobs

Jobs are automatically processed by the parallel executor, which:

- Maintains the configured number of parallel jobs
- Handles job failures with retries
- Provides detailed logging
- Collects metrics

## Monitoring

The template automatically configures:

- Process metrics
- Systemd service metrics
- Job execution statistics
- Prometheus integration

Access metrics at `http://localhost:9100/metrics`

## Troubleshooting

1. **Service Issues**:
   - Check logs: `journalctl -u ci-runner`
   - Verify service status: `systemctl status ci-runner`
   - Check job queue: `cat /tmp/ci-job-queue`

2. **Job Problems**:
   - Review job logs
   - Check retry attempts
   - Verify job queue status

3. **Performance Issues**:
   - Monitor parallel job count
   - Check system resources
   - Review metrics

## Best Practices

1. **Resource Management**:
   - Configure appropriate parallel job limits
   - Monitor system resource usage
   - Adjust retry parameters based on job type

2. **Error Handling**:
   - Set appropriate retry attempts
   - Configure suitable retry delays
   - Monitor failed jobs

3. **Monitoring**:
   - Set up alerts for service issues
   - Monitor job success rates
   - Track resource utilization

## Security Considerations

1. **Job Execution**:
   - Validate job commands
   - Restrict job permissions
   - Monitor job execution

2. **Resource Protection**:
   - Limit parallel jobs
   - Monitor resource usage
   - Implement job timeouts

## Testing

The template includes automated testing support with comprehensive test utilities:

### Test Utilities

The `tests/test-utils.sh` file provides common testing utilities:

- **Job Queue Testing**: `testJobQueue()` - Test job queue operations
- **Logging Testing**: `testLogging()` - Test logging functionality
- **Retry Mechanism Testing**: `testRetry()` - Test retry logic
- **Parallel Execution Testing**: `testParallelExecution()` - Test parallel job execution

### Test Categories

1. **Unit Tests** (`unit-tests.sh`):
   - Configuration validation
   - Job queue management
   - Parallel execution
   - Retry mechanism

2. **Integration Tests** (`integration-tests.sh`):
   - Service integration
   - Monitoring setup
   - Error handling
   - Logging verification

3. **Performance Tests** (`performance-tests.sh`):
   - Parallel execution
   - Resource utilization
   - Queue management

### Running Tests

Run tests with:

```bash
# Run all tests
./tests/unit-tests.sh
./tests/integration-tests.sh
./tests/performance-tests.sh

# Or use the test utilities directly
source tests/test-utils.sh
testJobQueue "test-job" "test-job"
```
