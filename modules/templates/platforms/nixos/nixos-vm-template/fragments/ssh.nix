{ config, pkgs, inputs, ... }:
{
  services.openssh.enable = true;

  # SSH Hardening
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";

  # Only allow login with SSH keys (add your public key below)
  users.users.example.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAA... user@host"
  ];
}
