{ config, pkgs, inputs, ... }:
{
  # CI/CD Runner Configuration

  # Docker support
  virtualisation.docker.enable = true;

  # Common CI tools
  environment.systemPackages = with pkgs; [
    git
    docker
    docker-compose
    nodejs
    python3
    rustc
    cargo
    go
    gcc
    make
    cmake
    ninja
  ];

  # Optional: Enable additional virtualization
  # virtualisation.podman.enable = true;
  # virtualisation.containerd.enable = true;

  # Optional: Enable Kubernetes tools
  # environment.systemPackages = with pkgs; [
  #   kubectl
  #   helm
  #   kind
  #   minikube
  # ];
}
