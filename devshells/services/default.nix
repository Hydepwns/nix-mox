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

    # Service tools
    pkgs.docker           # Container platform
    pkgs.docker-compose   # Multi-container orchestration
    pkgs.podman          # Container engine
    pkgs.podman-compose  # Podman compose
    pkgs.minikube        # Local Kubernetes
    pkgs.kubectl         # Kubernetes CLI
    pkgs.k9s             # Kubernetes CLI tool
    pkgs.kompose         # Docker Compose to Kubernetes
    pkgs.ctop            # Container metrics
    pkgs.dive            # Docker image analysis
    pkgs.lazydocker      # Docker TUI
    pkgs.consul          # Service mesh
    pkgs.nomad           # Workload orchestrator
    pkgs.vault           # Secrets management
    pkgs.terraform       # Infrastructure as code
    pkgs.ansible         # Configuration management
    pkgs.packer          # Machine image builder

    # Service development tools
    pkgs.just           # Command runner
    pkgs.direnv         # Directory environment manager
    pkgs.pre-commit     # Git hooks
    pkgs.act            # Run GitHub Actions locally
    pkgs.gh             # GitHub CLI
    pkgs.sd             # Intuitive find & replace
    pkgs.bat            # Better cat
    pkgs.eza            # Modern ls
    pkgs.tree           # Directory tree
    pkgs.duf            # Disk usage
    pkgs.htop           # Process viewer
    pkgs.jq             # JSON processor
    pkgs.yq             # YAML processor

    # Service testing tools
    pkgs.curl           # HTTP client
    pkgs.httpie         # User-friendly HTTP client
    pkgs.wget           # Web downloader
    pkgs.siege          # HTTP load testing
    pkgs.wrk            # HTTP benchmarking
    pkgs.k6             # Load testing
    pkgs.http-prompt    # Interactive HTTP client

    # Service debugging tools
    pkgs.gdb            # GNU debugger
    pkgs.tcpdump        # Network packet analyzer
    pkgs.wireshark      # Network protocol analyzer
    pkgs.ngrep          # Network grep
    pkgs.nmap           # Network mapper
    pkgs.netcat         # Network utility
    pkgs.socat          # Multipurpose relay
  ] ++ (if pkgs.stdenv.isLinux then [
    # Linux-specific packages
    pkgs.kubernetes     # Container orchestration
    pkgs.k3s            # Lightweight Kubernetes
    pkgs.kustomize      # Kubernetes configuration customization
    pkgs.strace         # System call tracer
    pkgs.ltrace         # Library call tracer
    pkgs.valgrind       # Memory debugging
    pkgs.bpftrace       # BPF-based tracing
  ] else []) ++ (if pkgs.system == "x86_64-linux" || pkgs.system == "x86_64-darwin" || pkgs.system == "aarch64-darwin" then [
    pkgs.insomnia       # API testing
  ] else []);

  shellHook = ''
    echo "Welcome to the nix-mox services shell!"
    echo ""
    echo "🔧 Service Tools"
    echo "--------------"
    echo "docker: (v${pkgs.docker.version}) [🐧 Linux] [🍎 macOS]"
    echo "    Commands:"
    echo "    - docker ps                     # List containers"
    echo "    - docker-compose up             # Start services"
    echo "    Dependencies:"
    echo "    - Requires: systemd (Linux)"
    echo ""
    echo "podman: (v${pkgs.podman.version}) [🐧 Linux] [🍎 macOS]"
    echo "    Commands:"
    echo "    - podman ps                     # List containers"
    echo "    - podman-compose up             # Start services"
    echo "    Configuration:"
    echo "    - ~/.config/containers/containers.conf"
    echo ""
    echo "kubernetes: (v${pkgs.kubernetes.version}) [🐧 Linux] [🍎 macOS]"
    echo "    Tools:"
    echo "    - kubectl: Kubernetes CLI"
    echo "    - k9s: TUI"
    echo "    Commands:"
    echo "    - kubectl get pods              # List pods"
    echo "    - k9s                           # Interactive TUI"
    echo ""
    echo "minikube: (v${pkgs.minikube.version}) [🐧 Linux] [🍎 macOS]"
    echo "    Commands:"
    echo "    - minikube start                # Start cluster"
    echo "    - minikube dashboard            # Open dashboard"
    echo "    Dependencies:"
    echo "    - Requires: docker or podman"
    echo ""
    echo "kompose: (v${pkgs.kompose.version}) [🐧 Linux] [🍎 macOS]"
    echo "    Commands:"
    echo "    - kompose convert               # Convert compose to k8s"
    echo "    - kompose up                    # Deploy to k8s"
    echo ""
    echo "Container Tools:"
    echo "ctop: (v${pkgs.ctop.version})"
    echo "    Commands:"
    echo "    - ctop                          # Container metrics"
    echo "    - ctop -a                       # Show all containers"
    echo ""
    echo "dive: (v${pkgs.dive.version})"
    echo "    Commands:"
    echo "    - dive image:tag                # Analyze image"
    echo "    - dive -t json image:tag        # Export as JSON"
    echo ""
    echo "lazydocker: (v${pkgs.lazydocker.version})"
    echo "    Commands:"
    echo "    - lazydocker                    # Docker TUI"
    echo "    - lazydocker --config ~/.config/lazydocker"
    echo ""
    echo "Infrastructure:"
    echo "terraform: (v${pkgs.terraform.version})"
    echo "    Commands:"
    echo "    - terraform init                # Initialize"
    echo "    - terraform plan                # Show changes"
    echo "    - terraform apply               # Apply changes"
    echo ""
    echo "ansible: (v${pkgs.ansible.version})"
    echo "    Commands:"
    echo "    - ansible-playbook playbook.yml # Run playbook"
    echo "    - ansible-inventory --list      # Show inventory"
    echo ""
    echo "packer: (v${pkgs.packer.version})"
    echo "    Commands:"
    echo "    - packer build template.json    # Build image"
    echo "    - packer validate template.json # Validate template"
    echo ""
    echo "📝 Quick Start"
    echo "------------"
    echo "1. Container management:"
    echo "   docker ps                        # List containers"
    echo "   docker-compose up                # Start services"
    echo "   podman ps                        # List containers"
    echo ""
    echo "2. Kubernetes:"
    echo "   minikube start                   # Start cluster"
    echo "   kubectl get pods                 # List pods"
    echo ""
    echo "3. Infrastructure:"
    echo "   terraform init                   # Initialize"
    echo "   ansible-playbook playbook.yml    # Run playbook"
    echo "   packer build template.json       # Build image"
    echo ""
    echo "For more information, see docs/."
  '';
}
