{ pkgs, config, helpers }:

let
  # Development IDE packages
  ide = with pkgs; [
    # Code editors
    vscode
    vim
    neovim
    emacs
    nano
    micro

    # IDEs
    jetbrains.idea-community
    jetbrains.pycharm-community
    jetbrains.clion
    jetbrains.webstorm

    # Terminal-based editors
    helix
    kakoune
    vis
  ];

  # Compilers and interpreters
  compilers = with pkgs; [
    # C/C++
    gcc
    clang
    cmake
    ninja
    make

    # Rust
    rustc
    cargo
    rust-analyzer

    # Go
    go
    gopls

    # Python
    python3
    python3Packages.pip
    python3Packages.setuptools

    # Node.js
    nodejs
    nodePackages.npm
    nodePackages.yarn

    # Java
    jdk
    maven
    gradle

    # Haskell
    ghc
    cabal-install
    stack

    # OCaml
    ocaml
    opam

    # Scala
    scala
    sbt

    # .NET
    dotnet-sdk

    # Web development
    deno
    bun
  ];

  # Debuggers and development tools
  debuggers = with pkgs; [
    # Debuggers
    gdb
    lldb
    valgrind
    strace
    ltrace

    # Profiling
    perf
    flamegraph
    hotspot

    # Static analysis
    clang-tools
    cppcheck
    sonar-scanner

    # Testing frameworks
    pytest
    jest
    mocha
    rspec

    # Documentation
    doxygen
    sphinx
    mkdocs
  ];

  # Development utilities
  utilities = with pkgs; [
    # Version control
    git
    git-lfs
    git-crypt
    hub
    gh

    # Build tools
    bazel
    buck
    pants

    # Package managers
    nix-prefetch-git
    nix-prefetch-url

    # Code quality
    pre-commit
    shellcheck
    hadolint
    yamllint
    jsonlint

    # Container tools
    docker
    docker-compose
    podman
    buildah
    skopeo

    # Cloud tools
    awscli2
    azure-cli
    gcloud
    kubectl
    helm

    # Monitoring and logging
    prometheus
    grafana
    elasticsearch
    kibana
    fluentd
  ];

  # Database tools
  databases = with pkgs; [
    # SQL databases
    postgresql
    mysql
    sqlite

    # NoSQL databases
    mongodb
    redis
    cassandra

    # Database tools
    pgadmin
    mysql-workbench
    dbeaver
    redis-commander
  ];

  # Web development
  webdev = with pkgs; [
    # Web servers
    nginx
    apacheHttpd
    caddy

    # Web frameworks
    nodePackages.express
    nodePackages.react
    nodePackages.vue
    nodePackages.angular

    # Build tools
    webpack
    rollup
    esbuild
    vite

    # CSS tools
    sass
    less
    postcss
    tailwindcss
  ];

  # Mobile development
  mobile = with pkgs; [
    # Android
    android-studio
    android-tools

    # iOS (macOS only)
    xcodebuild
    ios-deploy
  ];

  # Game development
  gamedev = with pkgs; [
    # Game engines
    godot
    unity3d

    # Graphics
    blender
    gimp
    inkscape

    # Audio
    audacity
    ardour
    lmms
  ];

  # AI/ML development
  aiml = with pkgs; [
    # Python ML libraries
    python3Packages.tensorflow
    python3Packages.pytorch
    python3Packages.scikit-learn
    python3Packages.pandas
    python3Packages.numpy
    python3Packages.matplotlib
    python3Packages.seaborn

    # Jupyter
    jupyter
    jupyterlab

    # Other ML tools
    octave
    r
    julia
  ];

in
{
  # Export all development packages
  inherit ide compilers debuggers utilities databases webdev mobile gamedev aiml;

  # Combined development environment
  full = ide ++ compilers ++ debuggers ++ utilities ++ databases ++ webdev ++ mobile ++ gamedev ++ aiml;

  # Minimal development environment
  minimal = with pkgs; [
    vscode
    git
    gcc
    python3
    nodejs
    docker
  ];

  # Web development focused
  web = ide ++ webdev ++ utilities;

  # Data science focused
  datascience = ide ++ aiml ++ utilities;

  # System programming focused
  systems = ide ++ compilers ++ debuggers ++ utilities;
}
