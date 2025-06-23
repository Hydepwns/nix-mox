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

    # Service tools (essential only)
    pkgs.docker # Container platform
    pkgs.docker-compose # Multi-container orchestration
    pkgs.kubectl # Kubernetes CLI
    pkgs.terraform # Infrastructure as code
    pkgs.ansible # Configuration management

    # Service development tools (essential only)
    pkgs.just # Command runner
    pkgs.direnv # Directory environment manager
    pkgs.pre-commit # Git hooks
    pkgs.gh # GitHub CLI
    pkgs.bat # Better cat
    pkgs.eza # Modern ls
    pkgs.jq # JSON processor

    # Service testing tools (essential only)
    pkgs.curl # HTTP client
    pkgs.httpie # User-friendly HTTP client
  ] ++ (if pkgs.stdenv.isLinux then [
    # Linux-specific packages (essential only)
    pkgs.minikube # Local Kubernetes
  ] else [ ]);

  shellHook = ''
    echo "Welcome to the nix-mox services shell!"
    echo ""
    echo "🔧 Service Tools"
    echo "--------------"
    echo "docker: (v${pkgs.docker.version}) [🐧 Linux] [🍎 macOS]"
    echo "    Commands:"
    echo "    - docker ps                     # List containers"
    echo "    - docker-compose up             # Start services"
    echo ""
    echo "kubectl: (v${pkgs.kubectl.version}) [🐧 Linux] [🍎 macOS]"
    echo "    Commands:"
    echo "    - kubectl get pods              # List pods"
    echo "    - kubectl apply -f file.yaml    # Apply configuration"
    echo ""
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
    echo "📝 Quick Start"
    echo "------------"
    echo "1. Container management:"
    echo "   docker ps                        # List containers"
    echo "   docker-compose up                # Start services"
    echo ""
    echo "2. Kubernetes:"
    echo "   kubectl get pods                 # List pods"
    echo ""
    echo "3. Infrastructure:"
    echo "   terraform init                   # Initialize"
    echo "   ansible-playbook playbook.yml    # Run playbook"
    echo ""
    echo "For more information, see docs/."
  '';
}
