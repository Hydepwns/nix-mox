{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../modules/error-handling.nix { inherit config lib pkgs; };

  # Template configuration
  cfg = config.services.nix-mox.message-queue;

  # Message queue types
  mqTypes = {
    rabbitmq = {
      package = pkgs.rabbitmq-server;
      service = "rabbitmq";
      configDir = "/etc/rabbitmq";
      logDir = "/var/log/rabbitmq";
      defaultPort = 5672;
      managementPort = 15672;
      metricsPort = 15692;
    };
    kafka = {
      package = pkgs.kafka;
      service = "kafka";
      configDir = "/etc/kafka";
      logDir = "/var/log/kafka";
      defaultPort = 9092;
      metricsPort = 9308;
    };
  };

  # Validation functions
  validateConfig = { mqType, ... }@config:
    let
      validMqTypes = builtins.attrNames mqTypes;
    in
    if !builtins.elem mqType validMqTypes then
      errorHandling.handleError 1 "Invalid message queue type: ${mqType}. Valid types: ${lib.concatStringsSep ", " validMqTypes}"
    else
      true;

  # Health check functions
  checkMessageQueueHealth = mqType:
    let
      mq = mqTypes.${mqType};
    in
    ''
      # Check if message queue is running
      if ! systemctl is-active --quiet ${mq.service}; then
        ${errorHandling.logMessage} "ERROR" "${mq.service} service is not running"
        exit 1
      fi

      # Check if message queue is listening on port
      if ! netstat -tuln | grep -q ":${toString mq.defaultPort} "; then
        ${errorHandling.logMessage} "ERROR" "${mq.service} is not listening on port ${toString mq.defaultPort}"
        exit 1
      fi

      # Check management port if enabled
      if [ "${toString cfg.enableManagement}" = "true" ]; then
        if ! netstat -tuln | grep -q ":${toString mq.managementPort} "; then
          ${errorHandling.logMessage} "ERROR" "${mq.service} management interface is not available on port ${toString mq.managementPort}"
          exit 1
        fi
      fi

      # Check metrics port if monitoring is enabled
      if [ "${toString cfg.enableMonitoring}" = "true" ]; then
        if ! netstat -tuln | grep -q ":${toString mq.metricsPort} "; then
          ${errorHandling.logMessage} "ERROR" "${mq.service} metrics are not available on port ${toString mq.metricsPort}"
          exit 1
        fi
      fi

      # Check message queue health
      if [ "${mqType}" = "rabbitmq" ]; then
        if ! ${pkgs.rabbitmq-server}/bin/rabbitmqctl status | grep -q "running_applications"; then
          ${errorHandling.logMessage} "ERROR" "RabbitMQ server is not healthy"
          exit 1
        fi
      elif [ "${mqType}" = "kafka" ]; then
        if ! ${pkgs.kafka}/bin/kafka-topics.sh --bootstrap-server localhost:${toString mq.defaultPort} --list | grep -q "test"; then
          ${errorHandling.logMessage} "ERROR" "Kafka server is not healthy"
          exit 1
        fi
      fi

      ${errorHandling.logMessage} "INFO" "${mq.service} health check passed"
    '';

  # Configuration setup functions
  setupConfig = mqType:
    let
      mq = mqTypes.${mqType};
    in
    ''
      # Set up message queue configuration
      if [ "${mqType}" = "rabbitmq" ]; then
        cat > ${mq.configDir}/rabbitmq.conf <<EOF
        listeners.tcp.default = ${toString mq.defaultPort}
        management.tcp.port = ${toString mq.managementPort}
        management.load_definitions = ${mq.configDir}/definitions.json
        vm_memory_high_watermark.relative = ${toString cfg.memoryLimit}
        disk_free_limit.absolute = ${toString cfg.diskLimit}MB
        ${lib.optionalString (cfg.password != null) "default_pass = ${cfg.password}"}
        ${lib.optionalString cfg.enableMonitoring "prometheus.tcp.port = ${toString mq.metricsPort}"}
        EOF

        cat > ${mq.configDir}/definitions.json <<EOF
        {
          "users": [
            {
              "name": "${cfg.username}",
              "password": "${cfg.password}",
              "tags": "administrator"
            }
          ],
          "vhosts": [
            {
              "name": "/"
            }
          ],
          "permissions": [
            {
              "user": "${cfg.username}",
              "vhost": "/",
              "configure": ".*",
              "write": ".*",
              "read": ".*"
            }
          ]
        }
        EOF
      elif [ "${mqType}" = "kafka" ]; then
        cat > ${mq.configDir}/server.properties <<EOF
        broker.id=0
        listeners=PLAINTEXT://:${toString mq.defaultPort}
        log.dirs=${cfg.dataDir}
        num.partitions=${toString cfg.partitions}
        num.recovery.threads.per.data.dir=${toString cfg.recoveryThreads}
        log.retention.hours=${toString cfg.retentionHours}
        log.segment.bytes=${toString cfg.segmentBytes}
        zookeeper.connect=${cfg.zookeeperConnect}
        ${lib.optionalString cfg.enableMonitoring "metric.reporters=org.apache.kafka.common.metrics.JmxReporter"}
        EOF
      fi

      ${errorHandling.logMessage} "INFO" "Set up configuration for ${mq.service}"
    '';

  # Monitoring setup functions
  setupMonitoring = mqType:
    let
      mq = mqTypes.${mqType};
    in
    ''
      # Add Prometheus metrics
      if [ "${mqType}" = "rabbitmq" ]; then
        ${pkgs.prometheus-rabbitmq-exporter}/bin/rabbitmq_exporter \
          --rabbit.url=http://localhost:${toString mq.managementPort} \
          --rabbit.user=${cfg.username} \
          --rabbit.password=${cfg.password} \
          --web.listen-address=:${toString mq.metricsPort} &
      elif [ "${mqType}" = "kafka" ]; then
        ${pkgs.prometheus-kafka-exporter}/bin/kafka_exporter \
          --kafka.server=localhost:${toString mq.defaultPort} \
          --web.listen-address=:${toString mq.metricsPort} &
      fi

      ${errorHandling.logMessage} "INFO" "Set up monitoring for ${mq.service}"
    '';

  # Backup setup functions
  setupBackup = mqType:
    let
      mq = mqTypes.${mqType};
    in
    ''
      # Set up backup script
      if [ "${mqType}" = "rabbitmq" ]; then
        cat > ${mq.configDir}/backup.sh <<EOF
        #!${pkgs.bash}/bin/bash
        set -e

        # Source error handling
        . ${errorHandling}/bin/template-error-handler

        # Create backup directory
        mkdir -p ${cfg.backupDir}

        # Create backup
        ${pkgs.rabbitmq-server}/bin/rabbitmqctl export_definitions > ${cfg.backupDir}/rabbitmq-\$(date +%Y%m%d-%H%M%S).json

        # Clean up old backups
        find ${cfg.backupDir} -name "rabbitmq-*.json" -mtime +${toString cfg.backupRetention} -delete

        ${errorHandling.logMessage} "INFO" "Created RabbitMQ backup"
        EOF
        chmod +x ${mq.configDir}/backup.sh
      elif [ "${mqType}" = "kafka" ]; then
        cat > ${mq.configDir}/backup.sh <<EOF
        #!${pkgs.bash}/bin/bash
        set -e

        # Source error handling
        . ${errorHandling}/bin/template-error-handler

        # Create backup directory
        mkdir -p ${cfg.backupDir}

        # Create backup
        ${pkgs.kafka}/bin/kafka-topics.sh --bootstrap-server localhost:${toString mq.defaultPort} --list | while read topic; do
          ${pkgs.kafka}/bin/kafka-topics.sh --bootstrap-server localhost:${toString mq.defaultPort} --describe --topic "\$topic" > ${cfg.backupDir}/kafka-\$(date +%Y%m%d-%H%M%S)-\$topic.txt
        done

        # Clean up old backups
        find ${cfg.backupDir} -name "kafka-*.txt" -mtime +${toString cfg.backupRetention} -delete

        ${errorHandling.logMessage} "INFO" "Created Kafka backup"
        EOF
        chmod +x ${mq.configDir}/backup.sh
      fi

      ${errorHandling.logMessage} "INFO" "Set up backup script for ${mq.service}"
    '';
in
{
  options.services.nix-mox.message-queue = {
    enable = lib.mkEnableOption "Enable message queue template";
    mqType = lib.mkOption {
      type = lib.types.enum (builtins.attrNames mqTypes);
      default = "rabbitmq";
      description = "Type of message queue to use";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Username for authentication";
    };
    password = lib.mkOption {
      type = lib.types.str;
      description = "Password for authentication";
    };
    enableManagement = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable management interface";
    };
    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable monitoring with Prometheus";
    };
    enableBackup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automated backups";
    };
    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/message-queue/backups";
      description = "Directory for backups";
    };
    backupRetention = lib.mkOption {
      type = lib.types.int;
      default = 7;
      description = "Number of days to retain backups";
    };
    memoryLimit = lib.mkOption {
      type = lib.types.float;
      default = 0.4;
      description = "Memory limit as a fraction of total memory (RabbitMQ only)";
    };
    diskLimit = lib.mkOption {
      type = lib.types.int;
      default = 1024;
      description = "Disk limit in MB (RabbitMQ only)";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/kafka";
      description = "Data directory (Kafka only)";
    };
    partitions = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of partitions per topic (Kafka only)";
    };
    recoveryThreads = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of recovery threads per data directory (Kafka only)";
    };
    retentionHours = lib.mkOption {
      type = lib.types.int;
      default = 168;
      description = "Log retention period in hours (Kafka only)";
    };
    segmentBytes = lib.mkOption {
      type = lib.types.int;
      default = 1073741824;
      description = "Log segment size in bytes (Kafka only)";
    };
    zookeeperConnect = lib.mkOption {
      type = lib.types.str;
      default = "localhost:2181";
      description = "ZooKeeper connection string (Kafka only)";
    };
    customConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Custom message queue configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate configuration
    assertions = [
      {
        assertion = validateConfig cfg;
        message = "Invalid message queue configuration";
      }
    ];

    # Add message queue package
    environment.systemPackages = with pkgs; [
      mqTypes.${cfg.mqType}.package
    ];

    # Create systemd service
    systemd.services."nix-mox-message-queue-${cfg.mqType}" = {
      description = "nix-mox message queue for ${cfg.mqType}";
      wantedBy = [ "multi-user.target" ];
      after = [ "${mqTypes.${cfg.mqType}.service}.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "message-queue" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Run health check
          ${checkMessageQueueHealth cfg.mqType}

          # Set up configuration
          ${setupConfig cfg.mqType}

          # Set up monitoring if enabled
          ${lib.optionalString cfg.enableMonitoring (setupMonitoring cfg.mqType)}

          # Set up backup if enabled
          ${lib.optionalString cfg.enableBackup (setupBackup cfg.mqType)}

          # Reload message queue configuration
          systemctl reload ${mqTypes.${cfg.mqType}.service}
        '';
      };
    };

    # Add monitoring configuration
    services.prometheus.exporters = lib.mkIf cfg.enableMonitoring {
      ${cfg.mqType} = {
        enable = true;
        port = mqTypes.${cfg.mqType}.metricsPort;
      };
    };

    # Add backup timer if enabled
    systemd.timers."nix-mox-message-queue-backup-${cfg.mqType}" = lib.mkIf cfg.enableBackup {
      description = "nix-mox message queue backup timer for ${cfg.mqType}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    systemd.services."nix-mox-message-queue-backup-${cfg.mqType}" = lib.mkIf cfg.enableBackup {
      description = "nix-mox message queue backup for ${cfg.mqType}";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${mqTypes.${cfg.mqType}.configDir}/backup.sh";
      };
    };
  };
} 