# CI Runner Example Configurations

This directory contains example configurations for different use cases of the CI Runner Template.

## Available Examples

### 1. Basic Example (`basic.nix`)

A simple configuration for running basic CI jobs:

- 2 parallel jobs
- Basic retry mechanism
- Standard logging
- Simple job queue

Usage:

```bash
nixos-rebuild switch -I nixos-config=./basic.nix
run-basic-jobs
```

### 2. High Performance (`high-performance.nix`)

Optimized for running many parallel jobs:

- 8 parallel jobs
- Shorter retry delays
- System performance tuning
- Batch job generation

Usage:

```bash
nixos-rebuild switch -I nixos-config=./high-performance.nix
run-high-performance-jobs
```

### 3. Fault Tolerant (`fault-tolerant.nix`)

Enhanced reliability for critical jobs:

- Extensive retry mechanism
- Longer retry delays
- Enhanced monitoring
- Job-level retry wrappers

Usage:

```bash
nixos-rebuild switch -I nixos-config=./fault-tolerant.nix
run-fault-tolerant-jobs
```

### 4. Development Environment (`development.nix`)

Configuration for development and debugging:

- Debugging tools included
- Detailed logging
- Strace integration
- Enhanced monitoring
- Development-specific job runners

Usage:

```bash
nixos-rebuild switch -I nixos-config=./development.nix
run-dev-jobs
```

## Customizing Examples

Each example can be customized by modifying:

1. Parallel job limits
2. Retry parameters
3. Logging levels
4. Monitoring configuration
5. Job definitions

## Best Practices

1. **Basic Usage**:
   - Start with the basic example
   - Adjust parallel jobs based on system resources
   - Monitor job execution

2. **High Performance**:
   - Tune system parameters
   - Monitor resource usage
   - Adjust parallel job limits

3. **Fault Tolerance**:
   - Configure appropriate retry attempts
   - Set suitable retry delays
   - Monitor job failures

4. **Development**:
   - Use debugging tools
   - Monitor detailed logs
   - Check strace output

## Monitoring

All examples include Prometheus metrics. Access them at:

```
http://localhost:9100/metrics
```

## Troubleshooting

1. Check service status:

   ```bash
   systemctl status ci-runner
   ```

2. View logs:

   ```bash
   journalctl -u ci-runner
   ```

3. Check job queue:

   ```bash
   cat /tmp/ci-job-queue
   ```

4. Monitor metrics:

   ```bash
   curl localhost:9100/metrics
   ```
