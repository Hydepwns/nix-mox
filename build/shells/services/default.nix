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

    # Service management tools
    pkgs.systemd        # System and service manager
    pkgs.supervisor     # Process control system
    pkgs.docker         # Container platform
    pkgs.docker-compose # Multi-container orchestration
    pkgs.podman         # Container engine
    pkgs.podman-compose # Podman compose
    pkgs.kubernetes     # Container orchestration
    pkgs.kubectl       # Kubernetes CLI
    pkgs.minikube      # Local Kubernetes
    pkgs.k3s           # Lightweight Kubernetes
    pkgs.k9s           # Kubernetes CLI tool
    pkgs.helm          # Kubernetes package manager
    pkgs.kustomize     # Kubernetes configuration customization

    # Service development tools
    pkgs.just           # Command runner
    pkgs.direnv        # Directory environment manager
    pkgs.pre-commit    # Git hooks
    pkgs.act           # Run GitHub Actions locally
    pkgs.gh            # GitHub CLI
    pkgs.sd            # Intuitive find & replace
    pkgs.bat           # Better cat
    pkgs.exa           # Modern ls
    pkgs.tree          # Directory tree
    pkgs.duf           # Disk usage
    pkgs.htop          # Process viewer
    pkgs.jq            # JSON processor
    pkgs.yq            # YAML processor

    # Service testing tools
    pkgs.curl          # HTTP client
    pkgs.httpie        # User-friendly HTTP client
    pkgs.wget          # Web downloader
    pkgs.siege         # HTTP load testing
    pkgs.ab            # Apache benchmark
    pkgs.wrk           # HTTP benchmarking
    pkgs.locust        # Load testing
    pkgs.k6            # Load testing
    pkgs.postman       # API testing
    pkgs.insomnia      # API testing
    pkgs.soapui        # API testing
    pkgs.restclient    # REST client
    pkgs.http-prompt   # Interactive HTTP client

    # Service debugging tools
    pkgs.strace        # System call tracer
    pkgs.ltrace        # Library call tracer
    pkgs.gdb           # GNU debugger
    pkgs.valgrind      # Memory debugging
    pkgs.perf          # Performance analysis
    pkgs.ftrace        # Function tracer
    pkgs.bpftrace      # BPF-based tracing
    pkgs.tcpdump       # Network packet analyzer
    pkgs.wireshark     # Network protocol analyzer
    pkgs.ngrep         # Network grep
    pkgs.nmap          # Network mapper
    pkgs.netcat        # Network utility
    pkgs.socat         # Multipurpose relay
  ];

  shellHook = ''
    echo "Welcome to the nix-mox services development shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo ""
    echo "Service Management:"
    echo "  - systemd: System and service manager"
    echo "  - supervisor: Process control system"
    echo "  - docker: Container platform"
    echo "  - kubernetes: Container orchestration"
    echo "  - k3s: Lightweight Kubernetes"
    echo ""
    echo "Service Development:"
    echo "  - just: Command runner"
    echo "  - direnv: Directory environment manager"
    echo "  - pre-commit: Git hooks"
    echo "  - act: Run GitHub Actions locally"
    echo "  - gh: GitHub CLI"
    echo ""
    echo "Service Testing:"
    echo "  - curl/httpie: HTTP clients"
    echo "  - siege/ab/wrk: Load testing"
    echo "  - locust/k6: Modern load testing"
    echo "  - postman/insomnia: API testing"
    echo ""
    echo "Service Debugging:"
    echo "  - strace/ltrace: System/library tracing"
    echo "  - gdb/valgrind: Debugging"
    echo "  - perf/ftrace: Performance analysis"
    echo "  - tcpdump/wireshark: Network analysis"
    echo ""
    echo "Run 'just' to see available commands."
  '';
}
