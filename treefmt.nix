{
  # This file defines the formatting configuration for the nix-mox project
  # It's used by treefmt to format various file types consistently

  # Project root file to identify the project
  projectRootFile = "flake.nix";

  # Global settings
  global = {
    # Exclude certain directories and files
    excludes = [
      "result"
      "result-*"
      ".git"
      ".github"
      "node_modules"
      "*.min.js"
      "*.min.css"
      "*.lock"
      "flake.lock"
      "tmp"
      "tmp-*"
      "version"
      "sbom"
      "coverage-tmp"
      "scripts"
    ];
  };

  # Formatter configurations
  formatter = {
    # Nix code formatting
    nix = {
      command = "nixpkgs-fmt";
      includes = [ "*.nix" ];
    };

    # Shell script formatting
    shell = {
      command = "shfmt";
      options = [
        "-i"
        "2"
        "-ci"
        "-sr"
        "-w"
      ];
      includes = [ "*.sh" "*.bash" "*.zsh" ];
    };

    # Shell script linting
    shellcheck = {
      command = "shellcheck";
      options = [
        "--color=always"
        "--shell=bash"
      ];
      includes = [ "*.sh" "*.bash" "*.zsh" "*.nu" ];
    };

    # Markdown formatting
    markdown = {
      command = "prettier";
      options = [
        "--parser"
        "markdown"
        "--prose-wrap"
        "always"
        "--print-width"
        "80"
      ];
      includes = [ "*.md" "*.mdx" ];
    };

    # JSON formatting
    json = {
      command = "prettier";
      options = [
        "--parser"
        "json"
        "--print-width"
        "80"
      ];
      includes = [ "*.json" ];
    };

    # YAML formatting
    yaml = {
      command = "prettier";
      options = [
        "--parser"
        "yaml"
        "--print-width"
        "80"
      ];
      includes = [ "*.yml" "*.yaml" ];
    };

    # JavaScript/TypeScript formatting
    javascript = {
      command = "prettier";
      options = [
        "--parser"
        "typescript"
        "--print-width"
        "80"
        "--semi"
        "true"
        "--single-quote"
        "true"
        "--trailing-comma"
        "es5"
      ];
      includes = [ "*.js" "*.ts" "*.jsx" "*.tsx" ];
    };

    # CSS/SCSS formatting
    css = {
      command = "prettier";
      options = [
        "--parser"
        "css"
        "--print-width"
        "80"
      ];
      includes = [ "*.css" "*.scss" "*.sass" ];
    };

    # HTML formatting
    html = {
      command = "prettier";
      options = [
        "--parser"
        "html"
        "--print-width"
        "80"
      ];
      includes = [ "*.html" "*.htm" ];
    };

    # Python formatting (commented out - black not available in devShell)
    # python = {
    #   command = "black";
    #   options = [
    #     "--line-length"
    #     "88"
    #     "--target-version"
    #     "py39"
    #   ];
    #   includes = [ "*.py" ];
    # };

    # Rust formatting (commented out - rustfmt not available in devShell)
    # rust = {
    #   command = "rustfmt";
    #   options = [
    #     "--edition"
    #     "2021"
    #   ];
    #   includes = [ "*.rs" ];
    # };

    # Go formatting (commented out - gofmt not available in devShell)
    # go = {
    #   command = "gofmt";
    #   options = [
    #     "-w"
    #     "-s"
    #   ];
    #   includes = [ "*.go" ];
    # };
  };
}
