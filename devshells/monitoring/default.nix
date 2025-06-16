{ pkgs }:
let
  lib = pkgs.lib;
in
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

    # Core monitoring stack
    pkgs.prometheus     # Monitoring system
    pkgs.grafana        # Metrics visualization
    pkgs.prometheus-alertmanager   # Alert routing

    # Prometheus exporters
    pkgs.prometheus-node-exporter    # System metrics
    pkgs.prometheus-blackbox-exporter # Blackbox monitoring
    pkgs.prometheus-snmp-exporter    # SNMP monitoring
    pkgs.prometheus-mysqld-exporter  # MySQL monitoring
    pkgs.prometheus-postgres-exporter # PostgreSQL monitoring
    pkgs.prometheus-redis-exporter   # Redis monitoring
    pkgs.prometheus-nginx-exporter   # Nginx monitoring
    pkgs.prometheus-haproxy-exporter # HAProxy monitoring

    # Logging stack
    pkgs.fluentd        # Log collector
    pkgs.fluent-bit     # Log processor
    pkgs.loki           # Log aggregation
    pkgs.promtail       # Log shipping

    # Tracing and APM
    pkgs.zipkin         # Distributed tracing
    pkgs.tempo          # Distributed tracing

    # Time series databases
    pkgs.influxdb       # Time series database
    pkgs.timescaledb    # Time series database
    pkgs.victoriametrics # Metrics storage
    pkgs.thanos         # Metrics storage
    pkgs.mimir          # Metrics storage

    # Metrics collection
    pkgs.telegraf       # Metrics collector
    pkgs.netdata        # Real-time monitoring

    # System monitoring
    pkgs.htop           # Process viewer
    pkgs.iftop          # Network monitoring
    pkgs.nload          # Network load

    # Network monitoring
    pkgs.tcpdump        # Network packet analyzer
    pkgs.wireshark      # Network protocol analyzer
    pkgs.ngrep          # Network grep
    pkgs.nmap           # Network mapper
    pkgs.netcat         # Network utility
    pkgs.socat          # Multipurpose relay

    # Data processing
    pkgs.jq             # JSON processor
    pkgs.yq             # YAML processor
    pkgs.xmlstarlet     # XML processor
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # Linux-only packages
    pkgs.collectd       # System metrics collection
    pkgs.dool           # System statistics
    pkgs.iotop          # I/O monitoring
    pkgs.sysstat        # System statistics
    pkgs.nethogs        # Network traffic
    pkgs.nmon           # System monitor
  ];

  shellHook = ''
    echo "Welcome to the nix-mox monitoring shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo ""
    echo "Core Monitoring Stack:"
    echo "  - prometheus: Monitoring system"
    echo "  - grafana: Metrics visualization"
    echo "  - alertmanager: Alert routing"
    echo ""
    echo "Prometheus Exporters:"
    echo "  - node-exporter: System metrics"
    echo "  - blackbox-exporter: Blackbox monitoring"
    echo "  - Various service exporters (MySQL, PostgreSQL, Redis, etc.)"
    echo ""
    echo "Logging Stack:"
    echo "  - fluentd/fluent-bit: Log collection"
    echo "  - loki: Log aggregation"
    echo "  - promtail: Log shipping"
    echo ""
    echo "Tracing and APM:"
    echo "  - jaeger/zipkin: Distributed tracing"
    echo "  - tempo: Distributed tracing"
    echo ""
    echo "Time Series Databases:"
    echo "  - influxdb/timescaledb: Time series storage"
    echo "  - victoriametrics/thanos: Metrics storage"
    echo "  - mimir: Metrics storage"
    echo ""
    echo "Metrics Collection:"
    echo "  - telegraf: Metrics collector"
    echo "  - netdata: Real-time monitoring"
    ${if pkgs.stdenv.isLinux then ''
    echo "  - dool: System statistics (Linux only)"
    echo "  - collectd: System metrics collection (Linux only)"
    '' else ""}
    echo ""
    echo "System Monitoring:"
    echo "  - htop: Process viewer"
    ${if pkgs.stdenv.isLinux then ''
    echo "  - iotop: I/O monitoring (Linux only)"
    echo "  - sysstat: System statistics (Linux only)"
    echo "  - nmon: System monitor (Linux only)"
    '' else ""}
    echo ""
    echo "Network Monitoring:"
    echo "  - tcpdump/wireshark: Network analysis"
    echo "  - nmap: Network mapping"
    echo "  - netcat/socat: Network utilities"
    ${if pkgs.stdenv.isLinux then ''
    echo "  - nethogs: Network traffic (Linux only)"
    '' else ""}
    echo ""
    echo "📊 Quick Start Guide"
    echo "-------------------"
    echo "1. Start Core Services:"
    echo "   prometheus --config.file=prometheus.yml"
    echo "   grafana-server"
    echo "   node_exporter"
    echo ""
    echo "2. Basic Prometheus Query Examples:"
    echo "   rate(node_cpu_seconds_total{mode='idle'}[5m])"
    echo "   node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100"
    echo "   rate(node_network_receive_bytes_total[5m])"
    echo ""
    echo "3. Log Collection:"
    echo "   promtail -config.file=promtail.yml"
    echo "   loki -config.file=loki.yml"
    echo ""
    echo "🔍 Common Monitoring Patterns"
    echo "---------------------------"
    echo "1. System Metrics:"
    echo "   node_exporter -> prometheus -> grafana"
    echo "   [Metrics] -> [Storage] -> [Visualization]"
    echo ""
    echo "2. Log Collection:"
    echo "   fluentd -> loki -> grafana"
    echo "   [Logs] -> [Storage] -> [Visualization]"
    echo ""
    echo "3. Distributed Tracing:"
    echo "   opentelemetry -> jaeger -> grafana"
    echo "   [Traces] -> [Storage] -> [Visualization]"
    echo ""
    echo "📈 Monitoring Stack Architecture"
    echo "-------------------------------"
    echo "                    [Grafana]"
    echo "                        ↑"
    echo "                        |"
    echo "        +---------------+---------------+"
    echo "        ↓               ↓               ↓"
    echo "  [Prometheus]     [Loki]         [Jaeger]"
    echo "        ↑               ↑               ↑"
    echo "        |               |               |"
    echo "  [Exporters]     [Promtail]     [OpenTelemetry]"
    echo "        ↑               ↑               ↑"
    echo "        |               |               |"
    echo "  [Services]      [Log Files]     [Applications]"
    echo ""
    echo "🔧 Common Commands"
    echo "----------------"
    echo "Metrics:"
    echo "  # View system metrics"
    echo "  curl localhost:9100/metrics | grep cpu"
    echo ""
    echo "  # Query Prometheus"
    echo "  curl -G 'http://localhost:9090/api/v1/query' --data-urlencode 'query=up'"
    echo ""
    echo "Logs:"
    echo "  # View Loki logs"
    echo "  curl -G 'http://localhost:3100/loki/api/v1/query_range' --data-urlencode 'query={job=\"varlogs\"}'"
    echo ""
    echo "Traces:"
    echo "  # View Jaeger traces"
    echo "  curl http://localhost:16686/api/traces"
    echo ""
    echo "System:"
    echo "  # Monitor system resources"
    echo "  htop"
    echo "  iotop"
    echo "  dool -tam"
    echo ""
    echo "Network:"
    echo "  # Capture network traffic"
    echo "  tcpdump -i any -w capture.pcap"
    echo "  nmap -sV localhost"
    echo ""
    echo "📝 Configuration Examples"
    echo "----------------------"
    echo "1. Prometheus (prometheus.yml):"
    echo "   global:"
    echo "     scrape_interval: 15s"
    echo "     evaluation_interval: 15s"
    echo ""
    echo "   scrape_configs:"
    echo "     - job_name: 'node'"
    echo "       static_configs:"
    echo "         - targets: ['localhost:9100']"
    echo ""
    echo "     - job_name: 'loki'"
    echo "       static_configs:"
    echo "         - targets: ['localhost:3100']"
    echo ""
    echo "2. Grafana (grafana.ini):"
    echo "   [server]"
    echo "   http_port = 3000"
    echo "   domain = localhost"
    echo ""
    echo "   [security]"
    echo "   admin_user = admin"
    echo "   admin_password = admin"
    echo ""
    echo "3. Loki (loki.yml):"
    echo "   auth_enabled: false"
    echo ""
    echo "   server:"
    echo "     http_listen_port: 3100"
    echo ""
    echo "   ingester:"
    echo "     lifecycler:"
    echo "       address: 127.0.0.1"
    echo "       ring:"
    echo "         kvstore:"
    echo "           store: inmemory"
    echo "         replication_factor: 1"
    echo "       final_sleep: 0s"
    echo "     chunk_idle_period: 5m"
    echo "     chunk_retain_period: 30s"
    echo ""
    echo "4. Promtail (promtail.yml):"
    echo "   server:"
    echo "     http_listen_port: 9080"
    echo "     grpc_listen_port: 0"
    echo ""
    echo "   positions:"
    echo "     filename: /tmp/positions.yaml"
    echo ""
    echo "   scrape_configs:"
    echo "     - job_name: system"
    echo "       static_configs:"
    echo "         - targets:"
    echo "             - localhost"
    echo "           labels:"
    echo "             job: varlogs"
    echo "             __path__: /var/log/*log"
    echo ""
    echo "5. Node Exporter Service:"
    echo "   [Unit]"
    echo "   Description=Node Exporter"
    echo "   After=network-online.target"
    echo ""
    echo "   [Service]"
    echo "   Type=simple"
    echo "   ExecStart=/usr/bin/node_exporter"
    echo "   Restart=always"
    echo ""
    echo "   [Install]"
    echo "   WantedBy=multi-user.target"
    echo ""
    echo "🔧 Configuration Management"
    echo "------------------------"
    echo "1. Create config directory:"
    echo "   mkdir -p ~/.config/nix-mox/monitoring"
    echo ""
    echo "2. Save configurations:"
    echo "   # Prometheus"
    echo "   cp prometheus.yml ~/.config/nix-mox/monitoring/"
    echo ""
    echo "   # Grafana"
    echo "   cp grafana.ini ~/.config/nix-mox/monitoring/"
    echo ""
    echo "   # Loki"
    echo "   cp loki.yml ~/.config/nix-mox/monitoring/"
    echo ""
    echo "   # Promtail"
    echo "   cp promtail.yml ~/.config/nix-mox/monitoring/"
    echo ""
    echo "3. Start services with configs:"
    echo "   prometheus --config.file=~/.config/nix-mox/monitoring/prometheus.yml"
    echo "   grafana-server --config=~/.config/nix-mox/monitoring/grafana.ini"
    echo "   loki -config.file=~/.config/nix-mox/monitoring/loki.yml"
    echo "   promtail -config.file=~/.config/nix-mox/monitoring/promtail.yml"
    echo ""
    echo "📊 Dashboard Examples"
    echo "-------------------"
    echo "1. Node Exporter Dashboard (node-exporter.json):"
    echo "   {"
    echo "     \"annotations\": {"
    echo "       \"list\": []"
    echo "     },"
    echo "     \"editable\": true,"
    echo "     \"fiscalYearStartMonth\": 0,"
    echo "     \"graphTooltip\": 0,"
    echo "     \"links\": [],"
    echo "     \"liveNow\": false,"
    echo "     \"panels\": ["
    echo "       {"
    echo "         \"datasource\": {"
    echo "           \"type\": \"prometheus\","
    echo "           \"uid\": \"prometheus\""
    echo "         },"
    echo "         \"fieldConfig\": {"
    echo "           \"defaults\": {"
    echo "             \"color\": {"
    echo "               \"mode\": \"palette-classic\""
    echo "             },"
    echo "             \"mappings\": [],"
    echo "             \"thresholds\": {"
    echo "               \"mode\": \"absolute\","
    echo "               \"steps\": ["
    echo "                 {"
    echo "                   \"color\": \"green\","
    echo "                   \"value\": null"
    echo "                 }"
    echo "               ]"
    echo "             }"
    echo "           },"
    echo "           \"overrides\": []"
    echo "         },"
    echo "         \"gridPos\": {"
    echo "           \"h\": 8,"
    echo "           \"w\": 12,"
    echo "           \"x\": 0,"
    echo "           \"y\": 0"
    echo "         },"
    echo "         \"id\": 1,"
    echo "         \"options\": {"
    echo "           \"orientation\": \"auto\","
    echo "           \"reduceOptions\": {"
    echo "             \"calcs\": ["
    echo "               \"lastNotNull\""
    echo "             ],"
    echo "             \"fields\": \"\","
    echo "             \"values\": false"
    echo "           },"
    echo "           \"showThresholdLabels\": false,"
    echo "           \"showThresholdMarkers\": true"
    echo "         },"
    echo "         \"pluginVersion\": \"9.5.2\","
    echo "         \"targets\": ["
    echo "           {"
    echo "             \"datasource\": {"
    echo "               \"type\": \"prometheus\","
    echo "               \"uid\": \"prometheus\""
    echo "             },"
    echo "             \"expr\": \"100 - (avg by (instance) (irate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)\","
    echo "             \"refId\": \"A\""
    echo "           }"
    echo "         ],"
    echo "         \"title\": \"CPU Usage\","
    echo "         \"type\": \"gauge\""
    echo "       }"
    echo "     ],"
    echo "     \"refresh\": \"5s\","
    echo "     \"schemaVersion\": 38,"
    echo "     \"style\": \"dark\","
    echo "     \"tags\": [],"
    echo "     \"templating\": {"
    echo "       \"list\": []"
    echo "     },"
    echo "     \"time\": {"
    echo "       \"from\": \"now-6h\","
    echo "       \"to\": \"now\""
    echo "     },"
    echo "     \"timepicker\": {},"
    echo "     \"timezone\": \"\","
    echo "     \"title\": \"Node Exporter\","
    echo "     \"uid\": \"node-exporter\","
    echo "     \"version\": 1,"
    echo "     \"weekStart\": \"\""
    echo "   }"
    echo ""
    echo "For more information, see the monitoring documentation."
  '';
}
