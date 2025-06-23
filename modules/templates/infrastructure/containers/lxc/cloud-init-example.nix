{ config, ... }:
{
  # Enable cloud-init for LXC/Proxmox or other cloud platforms
  services.cloud-init.enable = true;

  # Optionally, provide extra cloud-init configuration
  services.cloud-init.extraConfig = ''
    users:
      - name: myuser  # Change to your desired username
        ssh-authorized-keys:
          - ssh-rsa AAAA...yourkey...  # Replace with your SSH public key
    hostname: my-nixos-lxc  # Change to your desired hostname
    # Add more cloud-init options as needed
  '';
}
