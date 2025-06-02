# NixOS VM Template Example

## Quickstart

1. Copy this directory for your new VM type (e.g., web, db, ci-runner).
2. Edit `flake.nix` to set the hostname, user, and add your SSH key.
3. Build and deploy:

   ```sh
   nixos-rebuild switch --flake .#web-vm
   ```

4. (Optional) Enable first-boot or cloud-init modules by uncommenting them in the `modules` array for your VM.

> **WARNING:** Change the default password and set your own SSH key in `base.nix` before using in production! For best security, set the password to `null` and use SSH keys only.

## Multiple VM Roles

This template supports multiple VM types by exposing them as separate outputs in `flake.nix`. For example:

```nix
nixosConfigurations.example-vm = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./base.nix ];
};
nixosConfigurations.web-vm = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./base.nix
    ./web-server.nix
    # ./first-boot-setup.nix
    # ./cloud-init-example.nix
  ];
};
```

Add or customize roles by creating new `.nix` files and adding them to the `modules` array.

## Usage

- Clone this config and adjust the hostname and hardware settings as needed.
- Build and deploy using `nixos-rebuild switch --flake .#your-vm`.
- Store all changes in git for reproducibility.

## Converting a NixOS VM to a Proxmox Template

1. **Prepare the VM:**
   - Ensure the system is fully updated and configured as desired.
   - Remove any sensitive or host-specific data (SSH host keys, logs, etc.) if needed.
   - Optionally, run `nix-collect-garbage -d` to minimize disk usage.

2. **Shutdown the VM:**
   - From within the VM: `sudo poweroff`

3. **Convert to Template in Proxmox:**
   - In the Proxmox web UI, right-click the VM and select **Convert to template**.
   - Alternatively, use the CLI: `qm template <VMID>`

4. **Clone New VMs from Template:**
   - Use the Proxmox UI or CLI to create linked or full clones from the template.
   - For cloud-init or first-boot customization, see the next section.

**Best Practices:**

- Use this template as a base for different VM roles (web, DB, etc.) by customizing the flake or overlays before conversion.
- Document any manual steps required after cloning (e.g., regenerating SSH host keys).

## First Boot & Cloud-Init Automation

After cloning a VM from this template, you may want to automate post-clone setup (e.g., setting hostnames, regenerating SSH keys, running custom scripts). Here are several approaches:

### 1. NixOS-Native First-Boot Automation

You can add a systemd service or NixOS module that runs on first boot to perform tasks like:

- Regenerating SSH host keys
- Setting the hostname
- Running `nixos-generate-config` (for new hardware)
- Running custom scripts

**Example NixOS module snippet:**

```nix
# Add to your configuration.nix or flake module
systemd.services.first-boot-setup = {
  description = "First boot setup";
  wantedBy = [ "multi-user.target" ];
  serviceConfig.Type = "oneshot";
  script = ''
    #!/bin/sh
    # Regenerate SSH host keys
    rm -f /etc/ssh/ssh_host_*
    nixos-rebuild switch
    # Custom logic here
    # ...
    # Disable this service after first run
    systemctl disable first-boot-setup.service
  '';
};
```

### 2. Using nixos-infect

[`nixos-infect`](https://github.com/elitak/nixos-infect) lets you convert a generic Linux VM (e.g., Debian) to NixOS on first boot. This is useful if your cloud or VM provider only supports non-NixOS images.

- Launch a supported Linux VM
- Run the `nixos-infect` script (see repo for details)
- The VM will reboot into NixOS

### 3. Cloud-Init Example

Proxmox supports cloud-init for VM customization. NixOS has [cloud-init support](https://search.nixos.org/options?channel=23.11&show=services.cloud-init.enable&from=0&size=50&sort=relevance&type=packages&query=cloud-init).

**Example NixOS flake snippet:**

```nix
# In your NixOS configuration
{ config, ... }:
{
  services.cloud-init.enable = true;
  # Optionally, configure cloud-init modules
  services.cloud-init.extraConfig = ''
    users:
      - name: myuser
        ssh-authorized-keys:
          - ssh-rsa AAAA...yourkey...
    hostname: my-nixos-vm
    # ...
  '';
}
```

**Proxmox usage:**

- Add a cloud-init drive to your VM in Proxmox
- Set user, password, SSH key, etc. in the Proxmox UI
- On first boot, NixOS will apply these settings

---

Choose the approach that best fits your workflow. For most NixOS users, the native first-boot automation or cloud-init integration will be the most seamless.

---

## Using This Template for Different VM Types

This template is designed to be a flexible base for a variety of VM roles, such as web servers, database servers, CI runners, and more. To create a specialized VM type:

1. **Clone or copy this directory** for each new VM type or role.
2. **Customize the NixOS configuration**:
   - Change the hostname, networking, and hardware settings as needed.
   - Add or remove NixOS modules and packages for your use case (e.g., `services.nginx.enable = true;` for a web server, `services.postgresql.enable = true;` for a DB server).
   - Use overlays or flake inputs to add custom packages or modules.
3. **Import automation modules as needed**:
   - For first-boot logic, import `first-boot-setup.nix`:

     ```nix
     imports = [ ./first-boot-setup.nix ];
     ```

   - For cloud-init, import and customize `cloud-init-example.nix`:

     ```nix
     imports = [ ./cloud-init-example.nix ];
     ```

4. **Document any manual or post-clone steps** in your VM's README or configuration comments.

**Best Practices:**

- Keep each VM type in version control for reproducibility.
- Use Nix flakes to share common modules or overlays between VM types.
- Document any required secrets or environment variables separately (do not commit secrets to git).
- Test your template by cloning and booting a new VM before using in production.

---

By following these steps, you can quickly spin up new, immutable NixOS VMs tailored for any role in your infrastructure.

## Optional Modules: First Boot & Cloud-Init

To enable first-boot logic or cloud-init support, add the relevant module to your VM's `modules` array in `flake.nix`:

```nix
modules = [
  ./base.nix
  # ./web-server.nix
  ./first-boot-setup.nix  # For first-boot automation
  ./cloud-init-example.nix # For Proxmox cloud-init integration
];
```

- `first-boot-setup.nix`: Regenerates SSH host keys and runs custom logic on first boot.
- `cloud-init-example.nix`: Enables cloud-init for Proxmox or other platforms.

## Scrubbing Sensitive Data Before Templating

Before converting a VM to a template, run the following checklist:

- [ ] Remove SSH host keys: `sudo rm -f /etc/ssh/ssh_host_*`
- [ ] Clear logs: `sudo rm -rf /var/log/*`
- [ ] Clear shell history: `history -c && rm -f ~/.bash_history ~/.zsh_history`
- [ ] Remove temporary files: `sudo rm -rf /tmp/* /var/tmp/*`
- [ ] (Optional) Run `nix-collect-garbage -d`

## Local Testing with QEMU

You can test your VM template locally using QEMU:

```sh
nix build .#nixosConfigurations.web-vm.config.system.build.vm
./result/bin/run-*-vm
```

This boots the VM in a QEMU virtual machine for quick testing before uploading to Proxmox.

## Automated Flake Updates

This template includes a sample script and systemd unit for automatic flake updates:

- `nixos-flake-update.sh`: Updates the flake and rebuilds the system.
- `nixos-flake-update.service` and `.timer`: Run the update daily at 3:00 AM.

To enable the timer:

```sh
sudo cp nixos-flake-update.* /etc/systemd/system/
sudo cp nixos-flake-update.sh /etc/nixos/
sudo chmod +x /etc/nixos/nixos-flake-update.sh
sudo systemctl daemon-reload
sudo systemctl enable --now nixos-flake-update.timer
```

This will keep your VM up to date with the latest flake changes automatically.

## Minimal Example: Adding a New VM Role

To add a new VM type (e.g., CI runner):

1. Create `ci-runner.nix`:

   ```nix
   { config, pkgs, ... }:
   {
     imports = [ ./base.nix ];
     networking.hostName = "ci-runner";
     # Add CI-specific services or packages here
   }
   ```

2. Add to `flake.nix`:

   ```nix
   nixosConfigurations.ci-runner = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     modules = [ ./ci-runner.nix ];
   };
   ```

## Overriding Disk and Network Configuration

To adapt for different environments (KVM, VMware, etc.), copy and adjust the relevant sections in `base.nix`:

- `fileSystems` and `swapDevices` for disks
- `networking.interfaces` for network config
