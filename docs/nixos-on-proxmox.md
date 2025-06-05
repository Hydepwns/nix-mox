# NixOS on Proxmox Guide

This guide covers methods for deploying NixOS as either a container (LXC) or a virtual machine (VM) on a Proxmox host.

---

### LXC (Container)

Deploying NixOS in an LXC container is efficient and lightweight.

1.  **Download LXD Image**:
    You can find the latest official NixOS LXD container image on [Hydra](https://hydra.nixos.org/job/nixos/release-*/nixos.lxdContainerImage.x86_64-linux/latest).

2.  **Upload to Proxmox**:
    Upload the downloaded `.tar.xz` image to your Proxmox host's local storage via the Proxmox web UI (`Datacenter` -> `Storage` -> `local` -> `CT Templates` -> `Upload`).

3.  **Create the Container**:
    Use the `pct create` command to create the container.

    ```bash
    pct create <VMID> local:vztmpl/nixos-*.tar.xz \
      --ostype unmanaged --features nesting=1 \
      --net0 name=eth0,bridge=vmbr0,ip=dhcp
    ```

    - Replace `<VMID>` with a unique ID for your container.
    - The `--features nesting=1` flag is important for running certain applications, like Docker, inside the NixOS container.

4.  **Initial Configuration**:
    After creation, start the container and set a root password and add your SSH keys to ` /root/.ssh/authorized_keys` for remote access.

### VM (Declarative using nixos-generators)

For a fully-declarative VM, you can use [nixos-generators](https://github.com/nix-community/nixos-generators) to build a Proxmox-compatible VM image directly from a NixOS configuration.

1.  **Prepare your VM Configuration**:
    Ensure your NixOS configuration includes the QEMU guest agent for proper integration with Proxmox.

    ```nix
    # in your configuration.nix or vm.nix
    { config, ... }: {
      imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];
      services.qemuGuest.enable = true;
    }
    ```

2.  **Build the VM Image**:

    ```bash
    nixos-generate -f proxmox -c configuration.nix
    ```

    This command will produce a `.vma.zst` compressed image file.

3.  **Deploy on Proxmox**:
    - Upload the generated `.vma.zst` file to your Proxmox host's `vzdump` directory (e.g., `/var/lib/vz/dump/`).
    - Create a new VM in the Proxmox UI, then detach and remove its default disk.
    - Use the `qmrestore` command on the Proxmox host to create a new disk for the VM from your image: `qmrestore /path/to/your/image.vma.zst <VMID>`.
    - Attach the newly created disk to your VM.

4.  **Remote Updates**:
    You can update your VM remotely from your local machine using `nixos-rebuild`.

    ```bash
    nixos-rebuild switch --flake .#myVmName --target-host root@your-vm-ip
    ```

### Distroless NixOS (OCI/Container)

For minimal, secure container images, you can build a "distroless" image using `dockerTools`.

- **Minimal Image Example**:

  ```nix
  pkgs.dockerTools.buildImage {
    name = "distroless-app";
    # Only includes nginx and its runtime dependencies
    config = { Cmd = [ "${pkgs.nginx}/bin/nginx" "-g" "daemon off;" ]; };
  }
  ```

- **Multi-stage Build Example**:

  ```nix
  let
    # Build environment with all build-time dependencies
    buildEnv = pkgs.buildEnv { ... };
    # Runtime environment with only runtime dependencies
    runtimeEnv = pkgs.runtimeOnlyDependencies buildEnv;
  in
  pkgs.dockerTools.buildImage {
    # Copy only the runtime dependencies to the final image
    copyToRoot = runtimeEnv;
  }
  ```

- **Flake Configuration Example**:

  ```nix
  # in your flake.nix
  outputs = { nixpkgs, ... }: {
    nixosConfigurations.my-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ({ pkgs, ... }: {
        # Define the container's configuration
        environment.systemPackages = [ pkgs.nginx ];
        # It's good practice to set the state version
        system.stateVersion = "24.11";
        # Disable unnecessary things for a container
        boot.isContainer = true;
      }) ];
    };
  };
  ``` 
