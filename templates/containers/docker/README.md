# Docker Container Examples

This directory contains example NixOS modules for running containers with Docker (via oci-containers).

## Examples

### Nginx

- See `example-docker-service.nix` for running an Nginx container.

### Alpine Linux

- See `alpine-example.nix` for running a minimal Alpine Linux container.

## Usage

1. Import the desired example into your NixOS configuration:

   ```nix
   imports = [ ./example-docker-service.nix ./alpine-example.nix ];
   ```

2. The Alpine container will run `sleep infinity` by default to stay alive.
3. Customize the `command`, environment, or ports as needed in `alpine-example.nix`.

## Customization

- Edit the `command` to run a different process in the container.
- Uncomment and set `environment` or `ports` for your use case.
