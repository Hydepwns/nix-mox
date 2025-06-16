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
    pkgs.docker         # Container platform
    pkgs.docker-compose # Multi-container orchestration
    pkgs.podman         # Container engine
    pkgs.podman-compose # Podman compose
    pkgs.minikube      # Local Kubernetes
    pkgs.k9s           # Kubernetes CLI tool

    # Service development tools
    pkgs.just           # Command runner
    pkgs.direnv        # Directory environment manager
    pkgs.pre-commit    # Git hooks
    pkgs.act           # Run GitHub Actions locally
    pkgs.gh            # GitHub CLI
    pkgs.sd            # Intuitive find & replace
    pkgs.bat           # Better cat
    pkgs.eza           # Modern ls
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
    pkgs.wrk           # HTTP benchmarking
    pkgs.k6            # Load testing
    pkgs.insomnia      # API testing
    pkgs.http-prompt   # Interactive HTTP client

    # Service debugging tools
    pkgs.gdb           # GNU debugger
    pkgs.tcpdump       # Network packet analyzer
    pkgs.wireshark     # Network protocol analyzer
    pkgs.ngrep         # Network grep
    pkgs.nmap          # Network mapper
    pkgs.netcat        # Network utility
    pkgs.socat         # Multipurpose relay
  ] ++ (if pkgs.stdenv.isLinux then [
    # Linux-specific packages
    pkgs.systemd        # System and service manager
    pkgs.supervisord    # Process control system
    pkgs.apacheHttpd    # Apache benchmark
    pkgs.linuxPackages.perf  # Performance analysis
    pkgs.linuxPackages.ftrace  # Function tracer
    pkgs.kubernetes     # Container orchestration
    pkgs.kubectl       # Kubernetes CLI
    pkgs.k3s           # Lightweight Kubernetes
    pkgs.helm          # Kubernetes package manager
    pkgs.kustomize     # Kubernetes configuration customization
    pkgs.strace        # System call tracer
    pkgs.ltrace        # Library call tracer
    pkgs.valgrind      # Memory debugging
    pkgs.bpftrace      # BPF-based tracing
  ] else []);

  shellHook = let
    linuxHelp = ''
      echo "1. Systemd:"
      echo "   # List services"
      echo "   systemctl list-units --type=service"
      echo ""
      echo "   # Start/stop service"
      echo "   systemctl start service-name"
      echo "   systemctl stop service-name"
      echo ""
      echo "2. Docker:"
      echo "   # List containers"
      echo "   docker ps"
      echo ""
      echo "   # Build image"
      echo "   docker build -t myapp ."
      echo ""
      echo "3. Kubernetes:"
      echo "   # Get pods"
      echo "   kubectl get pods"
      echo ""
      echo "   # Apply manifest"
      echo "   kubectl apply -f manifest.yaml"
      echo ""
    '';
    macosHelp = ''
      echo "1. Launchd (macOS):"
      echo "   # List services"
      echo "   launchctl list"
      echo ""
      echo "   # Start/stop service"
      echo "   launchctl load ~/Library/LaunchAgents/service-name.plist"
      echo "   launchctl unload ~/Library/LaunchAgents/service-name.plist"
      echo ""
      echo "2. Docker:"
      echo "   # List containers"
      echo "   docker ps"
      echo ""
      echo "   # Build image"
      echo "   docker build -t myapp ."
      echo ""
    '';
    commonHelp = ''
      echo "📝 Service Patterns"
      echo "-----------------"
      echo "1. Container Deployment:"
      echo "   [Build] -> [Test] -> [Push] -> [Deploy]"
      echo "   [Image] -> [Verify] -> [Registry] -> [Cluster]"
      echo ""
      echo "2. Service Lifecycle:"
      echo "   [Develop] -> [Test] -> [Deploy] -> [Monitor]"
      echo "   [Code] -> [Verify] -> [Release] -> [Observe]"
      echo ""
      echo "3. Debugging Flow:"
      echo "   [Issue] -> [Trace] -> [Analyze] -> [Fix]"
      echo "   [Problem] -> [Logs] -> [Metrics] -> [Solution]"
      echo ""
      echo "🔍 Service Stack Architecture"
      echo "--------------------------"
      echo "                    [Cluster]"
      echo "                        ↑"
      echo "                        |"
      echo "        +---------------+---------------+"
      echo "        ↓               ↓               ↓"
      echo "  [Containers]    [Services]      [Ingress]"
      echo "        ↑               ↑               ↑"
      echo "        |               |               |"
      echo "  [Images]        [Deployments]    [Routes]"
      echo "        ↑               ↑               ↑"
      echo "        |               |               |"
      echo "  [Build]         [Config]         [DNS]"
      echo ""
      echo "📚 Configuration Examples"
      echo "----------------------"
      echo "1. Docker Compose (docker-compose.yml):"
      echo "   version: '3.8'"
      echo "   services:"
      echo "     app:"
      echo "       build: ."
      echo "       ports:"
      echo "         - '8080:8080'"
      echo "       environment:"
      echo "         - NODE_ENV=production"
      echo ""
    '';
    linuxConfig = ''
      echo "2. Kubernetes Deployment (deployment.yaml):"
      echo "   apiVersion: apps/v1"
      echo "   kind: Deployment"
      echo "   metadata:"
      echo "     name: myapp"
      echo "   spec:"
      echo "     replicas: 3"
      echo "     selector:"
      echo "       matchLabels:"
      echo "         app: myapp"
      echo "     template:"
      echo "       metadata:"
      echo "         labels:"
      echo "           app: myapp"
      echo "       spec:"
      echo "         containers:"
      echo "         - name: myapp"
      echo "           image: myapp:latest"
      echo "           ports:"
      echo "           - containerPort: 8080"
      echo ""
      echo "3. Systemd Service (myapp.service):"
      echo "   [Unit]"
      echo "   Description=My Application"
      echo "   After=network.target"
      echo ""
      echo "   [Service]"
      echo "   Type=simple"
      echo "   User=myapp"
      echo "   WorkingDirectory=/opt/myapp"
      echo "   ExecStart=/usr/bin/myapp"
      echo "   Restart=always"
      echo ""
      echo "   [Install]"
      echo "   WantedBy=multi-user.target"
      echo ""
      echo "4. Supervisor Config (supervisord.conf):"
      echo "   [program:myapp]"
      echo "   command=/usr/bin/myapp"
      echo "   directory=/opt/myapp"
      echo "   user=myapp"
      echo "   autostart=true"
      echo "   autorestart=true"
      echo "   stderr_logfile=/var/log/myapp.err.log"
      echo "   stdout_logfile=/var/log/myapp.out.log"
    '';
    macosConfig = ''
      echo "2. Launchd Service (myapp.plist):"
      echo "   <?xml version='1.0' encoding='UTF-8'?>"
      echo "   <!DOCTYPE plist PUBLIC '-//Apple//DTD PLIST 1.0//EN' 'http://www.apple.com/DTDs/PropertyList-1.0.dtd'>"
      echo "   <plist version='1.0'>"
      echo "   <dict>"
      echo "     <key>Label</key>"
      echo "     <string>com.example.myapp</string>"
      echo "     <key>ProgramArguments</key>"
      echo "     <array>"
      echo "       <string>/usr/local/bin/myapp</string>"
      echo "     </array>"
      echo "     <key>RunAtLoad</key>"
      echo "     <true/>"
      echo "     <key>KeepAlive</key>"
      echo "     <true/>"
      echo "     <key>StandardErrorPath</key>"
      echo "     <string>/var/log/myapp.err.log</string>"
      echo "     <key>StandardOutPath</key>"
      echo "     <string>/var/log/myapp.out.log</string>"
      echo "   </dict>"
      echo "   </plist>"
    '';
  in ''
    echo "Welcome to the nix-mox services development shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo ""
    echo "🔧 Service Management"
    echo "-------------------"
    ${if pkgs.stdenv.isLinux then linuxHelp else macosHelp}
    ${commonHelp}
    ${if pkgs.stdenv.isLinux then linuxConfig else macosConfig}
    echo ""
    echo "For more information, see the services documentation."
  '';
}
