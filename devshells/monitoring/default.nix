{ pkgs }:
let
  lib = pkgs.lib;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isAarch64 = pkgs.stdenv.isAarch64;

  # Common packages available on all platforms
  commonPackages = [
    pkgs.nushell
    pkgs.git
    pkgs.nix
    pkgs.nixpkgs-fmt
    pkgs.shellcheck
    pkgs.coreutils
    pkgs.fd
    pkgs.ripgrep
    pkgs.prometheus
    pkgs.grafana
    pkgs.loki
    pkgs.promtail
    pkgs.tempo
    pkgs.zipkin
    pkgs.logstash
  ];

  # Linux-specific packages
  linuxPackages = lib.optionals isLinux [
    pkgs.node-exporter
    pkgs.cadvisor
    pkgs.alertmanager
    pkgs.blackbox-exporter
    pkgs.snmp-exporter
    pkgs.pushgateway
    pkgs.jaeger
    pkgs.functionbeat
    pkgs.journalbeat
    pkgs.winlogbeat
  ];

  # Darwin-specific packages (disabled)
  darwinPackages = [];
in
pkgs.mkShell {
  buildInputs = if isDarwin then [] else (commonPackages ++ linuxPackages);

  shellHook = ''
    # Function to show help menu
    show_help() {
      echo "Welcome to the nix-mox Monitoring shell!"
      echo ""
      echo "🔧 Monitoring Tools"
      echo "----------------"
      echo "prometheus: (v${pkgs.prometheus.version})"
      echo "    Commands:"
      echo "    - prometheus                   # Start Prometheus"
      echo "    - promtool check rules         # Validate rules"
      echo "    Configuration:"
      echo "    - /etc/prometheus/prometheus.yml"
      echo ""
      echo "grafana: (v${pkgs.grafana.version})"
      echo "    Commands:"
      echo "    - grafana-server               # Start Grafana"
      echo "    - grafana-cli                  # CLI tool"
      echo "    Configuration:"
      echo "    - /etc/grafana/grafana.ini"
      echo ""
      echo "loki: (v${pkgs.loki.version})"
      echo "    Commands:"
      echo "    - loki                        # Start Loki"
      echo "    - loki --config.file=loki.yml"
      echo ""
      echo "promtail: (v${pkgs.promtail.version})"
      echo "    Commands:"
      echo "    - promtail                     # Start Promtail"
      echo "    - promtail --config.file=promtail.yml"
      echo ""
      echo "tempo: (v${pkgs.tempo.version})"
      echo "    Commands:"
      echo "    - tempo                        # Start Tempo"
      echo "    - tempo --config.file=tempo.yml"
      echo ""
      echo "zipkin: (v${pkgs.zipkin.version})"
      echo "    Commands:"
      echo "    - zipkin                       # Start Zipkin"
      echo "    - zipkin --port 9411           # Specify port"
      echo ""
      echo "logstash: (v${pkgs.logstash.version})"
      echo "    Commands:"
      echo "    - logstash                     # Start Logstash"
      echo "    - logstash-plugin install      # Install plugin"
      echo "    Configuration:"
      echo "    - /etc/logstash/logstash.yml"
      echo ""
      ${if isLinux then ''
      echo "node-exporter: (v${pkgs.node-exporter.version})"
      echo "    Commands:"
      echo "    - node_exporter                # Start node exporter"
      echo "    - node_exporter --web.listen-address=:9100"
      echo ""
      echo "cadvisor: (v${pkgs.cadvisor.version})"
      echo "    Commands:"
      echo "    - cadvisor                     # Start cAdvisor"
      echo "    - cadvisor -port 8080          # Specify port"
      echo ""
      echo "alertmanager: (v${pkgs.alertmanager.version})"
      echo "    Commands:"
      echo "    - alertmanager                 # Start Alertmanager"
      echo "    - amtool check-config          # Validate config"
      echo "    Configuration:"
      echo "    - /etc/alertmanager/alertmanager.yml"
      echo ""
      echo "blackbox-exporter: (v${pkgs.blackbox-exporter.version})"
      echo "    Commands:"
      echo "    - blackbox_exporter            # Start exporter"
      echo "    - blackbox_exporter --config.file=blackbox.yml"
      echo ""
      echo "snmp-exporter: (v${pkgs.snmp-exporter.version})"
      echo "    Commands:"
      echo "    - snmp_exporter                # Start exporter"
      echo "    - snmp_exporter --config.file=snmp.yml"
      echo ""
      echo "pushgateway: (v${pkgs.pushgateway.version})"
      echo "    Commands:"
      echo "    - pushgateway                  # Start Pushgateway"
      echo "    - pushgateway --web.listen-address=:9091"
      echo ""
      echo "jaeger: (v${pkgs.jaeger.version})"
      echo "    Commands:"
      echo "    - jaeger-all-in-one            # Start Jaeger"
      echo "    - jaeger-query                 # Query traces"
      echo ""
      echo "functionbeat: (v${pkgs.functionbeat.version})"
      echo "    Commands:"
      echo "    - functionbeat                 # Start Functionbeat"
      echo "    - functionbeat -e              # Log to stderr"
      echo "    Configuration:"
      echo "    - /etc/functionbeat/functionbeat.yml"
      echo ""
      echo "journalbeat: (v${pkgs.journalbeat.version})"
      echo "    Commands:"
      echo "    - journalbeat                  # Start Journalbeat"
      echo "    - journalbeat -e               # Log to stderr"
      echo "    Configuration:"
      echo "    - /etc/journalbeat/journalbeat.yml"
      echo ""
      echo "winlogbeat: (v${pkgs.winlogbeat.version})"
      echo "    Commands:"
      echo "    - winlogbeat                   # Start Winlogbeat"
      echo "    - winlogbeat -e                # Log to stderr"
      echo "    Configuration:"
      echo "    - /etc/winlogbeat/winlogbeat.yml"
      echo ""
      '' else ""}
      echo "📝 Quick Start"
      echo "------------"
      echo "1. Start core services:"
      echo "   prometheus                      # Start Prometheus"
      echo "   grafana-server                  # Start Grafana"
      echo ""
      echo "2. Start logging stack:"
      echo "   loki                            # Start Loki"
      echo "   promtail                        # Start Promtail"
      echo ""
      echo "3. Start tracing:"
      echo "   tempo                           # Start Tempo"
      echo "   jaeger-all-in-one               # Start Jaeger"
      echo ""
      echo "For more information, see docs/."
    }

    # Show initial help menu
    show_help

    # Add help command to shell
    echo ""
    echo "💡 Tip: Type 'help' to show this menu again"
    echo "💡 Tip: Type 'which-shell' to see which shell you're in"
    echo ""
    alias help='show_help'
    alias which-shell='echo "You are in the nix-mox Monitoring shell"'
  '';
}
