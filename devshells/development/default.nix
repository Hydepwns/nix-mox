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

    # Development tools
    pkgs.just           # Command runner
    pkgs.pre-commit     # Git hooks
    pkgs.direnv        # Directory environment manager
    pkgs.act           # Run GitHub Actions locally
    pkgs.gh            # GitHub CLI
    pkgs.sd            # Intuitive find & replace
    pkgs.bat           # Better cat
    pkgs.eza           # Modern ls
    pkgs.tree          # Directory tree
    pkgs.duf           # Disk usage
    pkgs.htop          # Process viewer
    pkgs.jq            # JSON processor
  ];

  shellHook = ''
    echo "Welcome to the nix-mox enhanced development shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo "  - Development tools"
    echo ""
    echo "🔧 Development Tools"
    echo "------------------"
    echo "1. Command Runner (just):"
    echo "   # List available commands"
    echo "   just"
    echo ""
    echo "   # Run a specific command"
    echo "   just build"
    echo "   just test"
    echo ""
    echo "2. Git Hooks (pre-commit):"
    echo "   # Install hooks"
    echo "   pre-commit install"
    echo ""
    echo "   # Run hooks manually"
    echo "   pre-commit run --all-files"
    echo ""
    echo "3. Directory Environment (direnv):"
    echo "   # Create .envrc"
    echo "   echo 'use nix' > .envrc"
    echo "   direnv allow"
    echo ""
    echo "4. GitHub Actions (act):"
    echo "   # List workflows"
    echo "   act -l"
    echo ""
    echo "   # Run a specific workflow"
    echo "   act -W .github/workflows/test.yml"
    echo ""
    echo "5. GitHub CLI (gh):"
    echo "   # List issues"
    echo "   gh issue list"
    echo ""
    echo "   # Create PR"
    echo "   gh pr create"
    echo ""
    echo "📝 Common Development Patterns"
    echo "--------------------------"
    echo "1. Project Setup:"
    echo "   [Repository] -> [direnv] -> [pre-commit] -> [just]"
    echo "   [Source] -> [Environment] -> [Hooks] -> [Commands]"
    echo ""
    echo "2. Development Workflow:"
    echo "   [Edit] -> [Test] -> [Commit] -> [Push] -> [PR]"
    echo "   [Code] -> [Verify] -> [Hook] -> [Remote] -> [Review]"
    echo ""
    echo "3. CI/CD Integration:"
    echo "   [Local] -> [GitHub] -> [Actions] -> [Deploy]"
    echo "   [act] -> [gh] -> [Workflows] -> [Release]"
    echo ""
    echo "🔍 Development Stack Architecture"
    echo "-------------------------------"
    echo "                    [GitHub]"
    echo "                        ↑"
    echo "                        |"
    echo "        +---------------+---------------+"
    echo "        ↓               ↓               ↓"
    echo "  [Local Dev]     [CI/CD]         [Review]"
    echo "        ↑               ↑               ↑"
    echo "        |               |               |"
    echo "  [direnv]        [act]           [gh]"
    echo "        ↑               ↑               ↑"
    echo "        |               |               |"
    echo "  [pre-commit]    [Workflows]     [PR/MR]"
    echo ""
    echo "📚 Configuration Examples"
    echo "----------------------"
    echo "1. justfile:"
    echo "   # List all available commands"
    echo "   default:"
    echo "       @just --list"
    echo ""
    echo "   # Build the project"
    echo "   build:"
    echo "       nix build"
    echo ""
    echo "   # Run tests"
    echo "   test:"
    echo "       nix flake check"
    echo ""
    echo "2. .pre-commit-config.yaml:"
    echo "   repos:"
    echo "   - repo: https://github.com/pre-commit/pre-commit-hooks"
    echo "     rev: v4.4.0"
    echo "     hooks:"
    echo "       - id: trailing-whitespace"
    echo "       - id: end-of-file-fixer"
    echo "       - id: check-yaml"
    echo "       - id: check-added-large-files"
    echo ""
    echo "3. .envrc:"
    echo "   use nix"
    echo "   layout python"
    echo "   dotenv"
    echo ""
    echo "4. GitHub Actions Workflow:"
    echo "   name: CI"
    echo "   on: [push, pull_request]"
    echo "   jobs:"
    echo "     build:"
    echo "       runs-on: ubuntu-latest"
    echo "       steps:"
    echo "         - uses: actions/checkout@v3"
    echo "         - uses: DeterminateSystems/nix-installer-action@main"
    echo "         - uses: DeterminateSystems/magic-nix-cache-action@main"
    echo "         - run: nix build"
    echo ""
    echo "For more information, see the development documentation."
  '';
}