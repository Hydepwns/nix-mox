{ pkgs }:
let
  lib = pkgs.lib;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

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
  ];

  # Linux-specific packages (essential only)
  linuxPackages = lib.optionals isLinux [
    pkgs.alertmanager
    pkgs.node-exporter
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
      echo ""
      echo "grafana: (v${pkgs.grafana.version})"
      echo "    Commands:"
      echo "    - grafana-server               # Start Grafana"
      echo "    - grafana-cli                  # CLI tool"
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
      ${if isLinux then ''
      ${if pkgs ? node-exporter then ''
      echo "node-exporter: (v${pkgs.node-exporter.version})"
      echo "    Commands:"
      echo "    - node_exporter                # Start node exporter"
      echo "    - node_exporter --web.listen-address=:9100"
      echo ""
      '' else ""}
      ${if pkgs ? alertmanager then ''
      echo "alertmanager: (v${pkgs.alertmanager.version})"
      echo "    Commands:"
      echo "    - alertmanager                 # Start Alertmanager"
      echo "    - amtool check-config          # Validate config"
      echo ""
      '' else ""}
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
    alias which-shell='echo "You are in the nix-mox monitoring shell"'
  '';
}
