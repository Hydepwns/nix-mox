# Containerized Services Example

This directory contains example configurations for running services in containers, using both LXC (Proxmox-native) and Docker (via NixOS modules).

- `lxc/`: Example LXC container config
- `docker/`: Example Docker service config

---

## Using This Template for Different Container Types

This template is designed to be a flexible base for a variety of container roles, such as web servers, database servers, CI runners, and more. To create a specialized container type:

1. **Clone or copy this directory** for each new container type or role.
2. **Customize the container configuration**:
   - Change the container name, networking, and hardware settings as needed.
   - Add or remove container modules and packages for your use case (e.g., `services.nginx.enable = true;` for a web server, `services.postgresql.enable = true;` for a DB server).
   - Use overlays or flake inputs to add custom packages or modules.
3. **Document any manual or post-clone steps** in your container's README or configuration comments.

**Best Practices:**

- Keep each container type in version control for reproducibility.
