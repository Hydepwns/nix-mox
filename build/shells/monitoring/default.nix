{ pkgs }:
pkgs.mkShell {
  buildInputs = [
    # Base tools from default shell
    pkgs.nushell
    pkgs.git
    pkgs.nix
    pkgs.nixpkgs-fmt
    pkgs.shellcheck
    pkgs.coreutils
    pkgs.fd
    pkgs.ripgrep

    # Monitoring and metrics
    pkgs.prometheus     # Monitoring system
    pkgs.grafana        # Metrics visualization
    pkgs.node-exporter  # System metrics exporter
    pkgs.alertmanager   # Alert routing
    pkgs.promtool      # Prometheus tools
    pkgs.prometheus-alertmanager # Alert manager
    pkgs.prometheus-pushgateway # Push gateway
    pkgs.prometheus-blackbox-exporter # Blackbox exporter
    pkgs.prometheus-snmp-exporter # SNMP exporter
    pkgs.prometheus-jmx-exporter # JMX exporter
    pkgs.prometheus-mysqld-exporter # MySQL exporter
    pkgs.prometheus-postgres-exporter # PostgreSQL exporter
    pkgs.prometheus-redis-exporter # Redis exporter
    pkgs.prometheus-nginx-exporter # Nginx exporter
    pkgs.prometheus-apache-exporter # Apache exporter
    pkgs.prometheus-haproxy-exporter # HAProxy exporter
    pkgs.prometheus-elasticsearch-exporter # Elasticsearch exporter
    pkgs.prometheus-kafka-exporter # Kafka exporter
    pkgs.prometheus-rabbitmq-exporter # RabbitMQ exporter
    pkgs.prometheus-memcached-exporter # Memcached exporter
    pkgs.prometheus-mongodb-exporter # MongoDB exporter
    pkgs.prometheus-consul-exporter # Consul exporter
    pkgs.prometheus-etcd-exporter # etcd exporter
    pkgs.prometheus-kubernetes-exporter # Kubernetes exporter
    pkgs.prometheus-docker-exporter # Docker exporter
    pkgs.prometheus-nomad-exporter # Nomad exporter
    pkgs.prometheus-vault-exporter # Vault exporter
    pkgs.prometheus-aws-exporter # AWS exporter
    pkgs.prometheus-gcp-exporter # GCP exporter
    pkgs.prometheus-azure-exporter # Azure exporter

    # Logging and tracing
    pkgs.fluentd        # Log collector
    pkgs.fluent-bit     # Log processor
    pkgs.logstash       # Log processing
    pkgs.filebeat       # Log shipper
    pkgs.packetbeat     # Network packet analyzer
    pkgs.metricbeat     # Metrics shipper
    pkgs.heartbeat      # Uptime monitoring
    pkgs.auditbeat      # Audit data
    pkgs.journalbeat    # Journald logs
    pkgs.winlogbeat     # Windows event logs
    pkgs.elasticsearch  # Search and analytics
    pkgs.kibana         # Data visualization
    pkgs.jaeger         # Distributed tracing
    pkgs.zipkin         # Distributed tracing
    pkgs.opentelemetry  # Observability framework
    pkgs.skywalking     # APM and tracing
    pkgs.pinpoint       # APM and tracing
    pkgs.datadog        # Monitoring and analytics
    pkgs.newrelic       # APM and monitoring
    pkgs.dynatrace      # APM and monitoring
    pkgs.appdynamics    # APM and monitoring
    pkgs.splunk         # Log analysis
    pkgs.graylog        # Log management
    pkgs.loki           # Log aggregation
    pkgs.tempo          # Distributed tracing
    pkgs.mimir          # Metrics storage
    pkgs.thanos         # Metrics storage
    pkgs.cortex         # Metrics storage
    pkgs.victoriametrics # Metrics storage
    pkgs.influxdb       # Time series database
    pkgs.timescaledb    # Time series database
    pkgs.graphite       # Time series database
    pkgs.opentsdb       # Time series database
    pkgs.warp10         # Time series database
    pkgs.kairosdb       # Time series database
    pkgs.chronograf     # Time series visualization
    pkgs.kapacitor      # Time series processing
    pkgs.telegraf       # Metrics collector
    pkgs.collectd       # Metrics collection
    pkgs.statsd         # Metrics aggregation
    pkgs.graphite-web   # Graphite web interface
    pkgs.grafana        # Metrics visualization
    pkgs.kibana         # Data visualization
    pkgs.elasticsearch  # Search and analytics
    pkgs.prometheus     # Monitoring system
    pkgs.alertmanager   # Alert routing
    pkgs.promtool       # Prometheus tools
    pkgs.prometheus-alertmanager # Alert manager
    pkgs.prometheus-pushgateway # Push gateway
    pkgs.prometheus-blackbox-exporter # Blackbox exporter
    pkgs.prometheus-snmp-exporter # SNMP exporter
    pkgs.prometheus-jmx-exporter # JMX exporter
    pkgs.prometheus-mysqld-exporter # MySQL exporter
    pkgs.prometheus-postgres-exporter # PostgreSQL exporter
    pkgs.prometheus-redis-exporter # Redis exporter
    pkgs.prometheus-nginx-exporter # Nginx exporter
    pkgs.prometheus-apache-exporter # Apache exporter
    pkgs.prometheus-haproxy-exporter # HAProxy exporter
    pkgs.prometheus-elasticsearch-exporter # Elasticsearch exporter
    pkgs.prometheus-kafka-exporter # Kafka exporter
    pkgs.prometheus-rabbitmq-exporter # RabbitMQ exporter
    pkgs.prometheus-memcached-exporter # Memcached exporter
    pkgs.prometheus-mongodb-exporter # MongoDB exporter
    pkgs.prometheus-consul-exporter # Consul exporter
    pkgs.prometheus-etcd-exporter # etcd exporter
    pkgs.prometheus-kubernetes-exporter # Kubernetes exporter
    pkgs.prometheus-docker-exporter # Docker exporter
    pkgs.prometheus-nomad-exporter # Nomad exporter
    pkgs.prometheus-vault-exporter # Vault exporter
    pkgs.prometheus-aws-exporter # AWS exporter
    pkgs.prometheus-gcp-exporter # GCP exporter
    pkgs.prometheus-azure-exporter # Azure exporter

    # System monitoring
    pkgs.htop           # Process viewer
    pkgs.iotop          # I/O monitoring
    pkgs.iftop          # Network monitoring
    pkgs.nethogs        # Network traffic
    pkgs.nload          # Network load
    pkgs.nmon           # System monitor
    pkgs.sar            # System activity
    pkgs.sysstat        # System statistics
    pkgs.dstat          # System statistics
    pkgs.netdata        # Real-time monitoring
    pkgs.zabbix         # Enterprise monitoring
    pkgs.nagios         # Network monitoring
    pkgs.icinga         # Network monitoring
    pkgs.shinken        # Network monitoring
    pkgs.sensu          # Monitoring framework
    pkgs.prometheus-node-exporter # Node exporter
    pkgs.prometheus-cadvisor # Container monitoring
    pkgs.prometheus-blackbox-exporter # Blackbox exporter
    pkgs.prometheus-snmp-exporter # SNMP exporter
    pkgs.prometheus-jmx-exporter # JMX exporter
    pkgs.prometheus-mysqld-exporter # MySQL exporter
    pkgs.prometheus-postgres-exporter # PostgreSQL exporter
    pkgs.prometheus-redis-exporter # Redis exporter
    pkgs.prometheus-nginx-exporter # Nginx exporter
    pkgs.prometheus-apache-exporter # Apache exporter
    pkgs.prometheus-haproxy-exporter # HAProxy exporter
    pkgs.prometheus-elasticsearch-exporter # Elasticsearch exporter
    pkgs.prometheus-kafka-exporter # Kafka exporter
    pkgs.prometheus-rabbitmq-exporter # RabbitMQ exporter
    pkgs.prometheus-memcached-exporter # Memcached exporter
    pkgs.prometheus-mongodb-exporter # MongoDB exporter
    pkgs.prometheus-consul-exporter # Consul exporter
    pkgs.prometheus-etcd-exporter # etcd exporter
    pkgs.prometheus-kubernetes-exporter # Kubernetes exporter
    pkgs.prometheus-docker-exporter # Docker exporter
    pkgs.prometheus-nomad-exporter # Nomad exporter
    pkgs.prometheus-vault-exporter # Vault exporter
    pkgs.prometheus-aws-exporter # AWS exporter
    pkgs.prometheus-gcp-exporter # GCP exporter
    pkgs.prometheus-azure-exporter # Azure exporter
  ];

  shellHook = ''
    echo "Welcome to the nix-mox monitoring shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo ""
    echo "Metrics and Monitoring:"
    echo "  - prometheus: Monitoring system"
    echo "  - grafana: Metrics visualization"
    echo "  - node-exporter: System metrics"
    echo "  - alertmanager: Alert routing"
    echo ""
    echo "Logging and Tracing:"
    echo "  - fluentd/fluent-bit: Log collection"
    echo "  - elasticsearch/kibana: Log analysis"
    echo "  - jaeger/zipkin: Distributed tracing"
    echo "  - loki/tempo: Log and trace storage"
    echo ""
    echo "Time Series Databases:"
    echo "  - influxdb/timescaledb: Time series storage"
    echo "  - graphite/opentsdb: Time series storage"
    echo "  - victoriametrics/thanos: Metrics storage"
    echo ""
    echo "System Monitoring:"
    echo "  - htop/iotop: Process and I/O monitoring"
    echo "  - netdata: Real-time monitoring"
    echo "  - zabbix/nagios: Enterprise monitoring"
    echo ""
    echo "Run 'prometheus --config.file=prometheus.yml' to start Prometheus."
  '';
}
