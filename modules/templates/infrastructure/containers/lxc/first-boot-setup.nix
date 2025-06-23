{ config, pkgs, ... }:
{
  systemd.services.first-boot-setup = {
    description = "First boot setup (regenerate SSH keys, custom logic)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      #!/bin/sh
      echo "[first-boot-setup] Regenerating SSH host keys..."
      rm -f /etc/ssh/ssh_host_*
      nixos-rebuild switch
      # Add custom first-boot logic here
      # ...
      echo "[first-boot-setup] Disabling service after first run."
      systemctl disable first-boot-setup.service
    '';
  };
}
