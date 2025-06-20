# Message Queue Template

This template provides a flexible and powerful message queue solution with support for both RabbitMQ and Kafka. It includes features for high availability, monitoring, backups, and custom configuration.

## Features

- Support for multiple message queue types:
  - RabbitMQ
  - Kafka
- Health checks and monitoring
- Management interface
- Automated backups
- Memory and disk management
- Authentication support
- Prometheus metrics integration
- Custom configuration options
- Error handling and logging

## Usage

### Basic Configuration

```nix
services.nix-mox.message-queue = {
  enable = true;
  mqType = "rabbitmq";  # or "kafka"
  username = "admin";
  password = "secure_password";
  enableManagement = true;
  enableMonitoring = true;
  enableBackup = true;
  backupDir = "/var/lib/message-queue/backups";
  backupRetention = 7;  # days
};
```

### Advanced Configuration

```nix
services.nix-mox.message-queue = {
  enable = true;
  mqType = "rabbitmq";
  username = "admin";
  password = "secure_password";
  enableManagement = true;
  enableMonitoring = true;
  enableBackup = true;
  backupDir = "/var/lib/message-queue/backups";
  backupRetention = 30;
  memoryLimit = 0.4;  # 40% of total memory
  diskLimit = 2048;  # MB
  customConfig = {
    tcpKeepAlive = 300;
    heartbeat = 60;
    channelMax = 0;
  };
};
```

### Kafka Configuration

```nix
services.nix-mox.message-queue = {
  enable = true;
  mqType = "kafka";
  enableMonitoring = true;
  enableBackup = true;
  backupDir = "/var/lib/message-queue/backups";
  backupRetention = 30;
  dataDir = "/var/lib/kafka";
  partitions = 3;
  recoveryThreads = 2;
  retentionHours = 168;  # 7 days
  segmentBytes = 1073741824;  # 1GB
  zookeeperConnect = "localhost:2181";
  customConfig = {
    num.network.threads = 3;
    num.io.threads = 8;
    background.threads = 10;
    queued.max.requests = 500;
  };
};
```

## Configuration Options

### Message Queue Type

- `mqType`: Type of message queue to use
  - Options: "rabbitmq" or "kafka"
  - Default: "rabbitmq"

### Basic Settings

- `username`: Username for authentication
  - Default: "admin"
- `password`: Password for authentication
  - Required
- `enableManagement`: Enable management interface
  - Default: true
- `enableMonitoring`: Enable Prometheus monitoring
  - Default: true
- `enableBackup`: Enable automated backups
  - Default: true
- `backupDir`: Directory for backups
  - Default: "/var/lib/message-queue/backups"
- `backupRetention`: Number of days to retain backups
  - Default: 7

### RabbitMQ-specific Settings

- `memoryLimit`: Memory limit as a fraction of total memory
  - Default: 0.4 (40%)
- `diskLimit`: Disk limit in MB
  - Default: 1024

### Kafka-specific Settings

- `dataDir`: Data directory
  - Default: "/var/lib/kafka"
- `partitions`: Number of partitions per topic
  - Default: 1
- `recoveryThreads`: Number of recovery threads per data directory
  - Default: 1
- `retentionHours`: Log retention period in hours
  - Default: 168 (7 days)
- `segmentBytes`: Log segment size in bytes
  - Default: 1073741824 (1GB)
- `zookeeperConnect`: ZooKeeper connection string
  - Default: "localhost:2181"

### Custom Configuration

- `customConfig`: Additional message queue configuration
  - Type: attribute set
  - Optional

## Health Checks

The template performs the following health checks:

1. Message queue service status
2. Port availability
3. Management interface (if enabled)
4. Metrics availability (if monitoring is enabled)
5. Message queue health

## Monitoring

### Prometheus Integration

- RabbitMQ exporter: Port 15692
- Kafka exporter: Port 9308
- Metrics available:
  - Queue statistics
  - Connection counts
  - Message rates
  - Consumer lag
  - Broker status
  - Topic statistics

## Management Interface

### RabbitMQ

- URL: <http://localhost:15672>
- Authentication required
- Queue management
- Exchange management
- User management
- Cluster status
- Performance metrics

### Kafka

- Topic management
- Partition management
- Consumer group management
- Broker status
- Performance metrics

## Backup

### RabbitMQ Backup

- Exports definitions (users, vhosts, permissions)
- Daily automated backups
- Configurable retention period
- Backup rotation

### Kafka Backup

- Exports topic configurations
- Daily automated backups
- Configurable retention period
- Backup rotation

## Error Handling

The template uses the standardized error handling module for:

- Configuration validation
- Service status checks
- Health check failures
- Monitoring setup
- Backup operations
- Logging

## Examples

### Basic RabbitMQ Setup

```nix
services.nix-mox.message-queue = {
  enable = true;
  mqType = "rabbitmq";
  username = "admin";
  password = "secure_password";
  enableManagement = true;
  enableMonitoring = true;
  enableBackup = true;
};
```

### Kafka with Custom Settings

```nix
services.nix-mox.message-queue = {
  enable = true;
  mqType = "kafka";
  enableMonitoring = true;
  enableBackup = true;
  backupRetention = 14;
  partitions = 3;
  recoveryThreads = 2;
  retentionHours = 168;
  segmentBytes = 1073741824;
  zookeeperConnect = "localhost:2181";
  customConfig = {
    num.network.threads = 3;
    num.io.threads = 8;
    background.threads = 10;
    queued.max.requests = 500;
  };
};
```

## Troubleshooting

### Common Issues

1. Service not starting
   - Check systemd logs: `journalctl -u nix-mox-message-queue-{rabbitmq,kafka}`
   - Verify configuration syntax
   - Check port availability

2. Management interface not accessible
   - Verify management is enabled
   - Check authentication credentials
   - Verify port availability

3. Monitoring not working
   - Check Prometheus exporter status
   - Verify port availability
   - Check Prometheus configuration

4. Backup failures
   - Check backup directory permissions
   - Verify disk space
   - Check backup script logs

### Logs

- Systemd logs: `journalctl -u nix-mox-message-queue-{rabbitmq,kafka}`
- RabbitMQ logs: `/var/log/rabbitmq/rabbit.log`
- Kafka logs: `/var/log/kafka/server.log`
- Backup logs: `journalctl -u nix-mox-message-queue-backup-{rabbitmq,kafka}`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This template is licensed under the MIT License.
