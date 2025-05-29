- Add users, services, or automation as needed for your use case.

## Automation Examples

You can automate post-clone or first-boot setup in your LXC container using the provided example modules:

### First Boot Automation

- Import `first-boot-setup.nix` in your `default.nix`:

  ```nix
  imports = [ ./first-boot-setup.nix ];
  ```

- This will run a systemd service on first boot to regenerate SSH host keys and run any custom logic you add.

### Cloud-Init Support

- Import `cloud-init-example.nix` in your `default.nix`:

  ```nix
  imports = [ ./cloud-init-example.nix ];
  ```

- This enables cloud-init for the container, allowing you to set users, SSH keys, and hostname via Proxmox or other cloud platforms.
- Customize the user, SSH key, and hostname in `cloud-init-example.nix` as needed.
