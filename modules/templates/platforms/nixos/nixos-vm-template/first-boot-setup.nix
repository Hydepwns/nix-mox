{ config, pkgs, ... }:
{
  systemd.services.first-boot-setup = {
    description = "First boot setup (regenerate SSH keys, custom logic)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = "/bin/sh -c '[ -f /var/lib/first-boot-setup.done ] || (echo " [ first-boot-setup ] Regenerating SSH host keys..." && rm -f /etc/ssh/ssh_host_* && nixos-rebuild switch && touch /var/lib/first-boot-setup.done && echo "[first-boot-setup] Completed.")'";
  };
}
