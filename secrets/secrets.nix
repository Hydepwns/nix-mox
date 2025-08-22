# Agenix secrets configuration
let
  # Hydepwns keys (from config/personal/keys/hydepwns.pub)
  hydepwns-key1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLBxcR9VSq3yeN3D8LI66ul/aOB7wpk+qyYQifpwiO5";
  hydepwns-key2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBNSCpvPKO9IeEFifTgS0IFle7iMWKtvDr5bngKcDu8b";
  hydepwns-key3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEMQM/yvM8EAHY/bR10dbS2hhMFFc2OscWe8t1V8QZUb";
  hydepwns-key4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBTTJ3T+lOaKg/xN83IwR8gcHLYGj0Aj6uW5OaXyPCB2";

  # System keys (for the NixOS system itself)
  nixos-system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqq8F2XmvhXRSqL3mJrE4Hdo1gDM1nc6XzVUD0z7oH root@nixos";

  # All authorized keys
  allKeys = [ hydepwns-key1 hydepwns-key2 hydepwns-key3 hydepwns-key4 nixos-system ];

  # Keys for development (macOS)
  devKeys = [ hydepwns-key2 ];

  # Keys for production NixOS system
  prodKeys = [ hydepwns-key1 hydepwns-key3 hydepwns-key4 nixos-system ];
in
{
  # WiFi passwords
  "wifi-home.age".publicKeys = allKeys;
  "wifi-work.age".publicKeys = allKeys;
  "wifi-guest.age".publicKeys = allKeys;

  # User passwords
  "hydepwns-password.age".publicKeys = allKeys;

  # SSH keys for services
  "ssh-github.age".publicKeys = allKeys;
  "ssh-gitlab.age".publicKeys = allKeys;
  "ssh-axol.age".publicKeys = allKeys;

  # API tokens and keys
  "github-token.age".publicKeys = allKeys;
  "openai-key.age".publicKeys = devKeys;
  "anthropic-key.age".publicKeys = devKeys;

  # Service passwords
  "database-password.age".publicKeys = prodKeys;
  "nextcloud-admin.age".publicKeys = prodKeys;
  "grafana-admin.age".publicKeys = prodKeys;

  # VPN configurations
  "wireguard-config.age".publicKeys = allKeys;
  "tailscale-key.age".publicKeys = allKeys;

  # Gaming services
  "steam-credentials.age".publicKeys = prodKeys;
  "discord-token.age".publicKeys = allKeys;
}
