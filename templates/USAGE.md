# Template Usage & Best Practices

This guide applies to all templates in the `templates/` directory, including containers, VMs, monitoring, and storage examples.

---

## Table of Contents

- [How to Use a Template](#how-to-use-a-template)
- [Best Practices](#best-practices)
- [Example: Importing a Template Module](#example-importing-a-template-module)
- [Available Templates Overview](#available-templates-overview)

---

## How to Use a Template

1. **Copy or clone the template directory** for your new service, VM, or role.
2. **Customize configuration files**:
   - Change names, networking, and hardware settings as needed.
   - Add or remove NixOS modules and packages for your use case (e.g., `services.nginx.enable = true;` for a web server).
   - Use overlays or flake inputs to add custom packages or modules.
3. **Import the relevant `.nix` files** into your NixOS configuration:
   - Example:

     ```nix
     imports = [ ./example-docker-service.nix ./alpine-example.nix ];
     ```

   - For LXC or VM templates, import `default.nix` or other modules as needed.
4. **Document any manual or post-clone steps** in your template's README or configuration comments.

---

## Best Practices

- **Version Control:** Keep each template or service type in git for reproducibility.
- **Documentation:** Document any manual steps required after cloning (e.g., regenerating SSH host keys, setting passwords).
- **Security:** Remove sensitive data (e.g., SSH host keys, default passwords) before using a template in production.
- **Customization:** Use Nix flakes or overlays to share common modules or settings between templates.
- **Testing:** Test your template by deploying or cloning before using in production.
- **Secrets:** Document required secrets or environment variables separately; do not commit secrets to git.

---

## Example: Importing a Template Module

```nix
# In your NixOS configuration
imports = [ ./path/to/template.nix ];
```

---

## Available Templates Overview

This directory contains example templates and configuration files for improving your Proxmox + NixOS + Windows infrastructure. These examples cover:

- Immutable NixOS VM template configuration
- Containerized service configuration (LXC and Docker)
- ZFS SSD caching setup
- Prometheus + Grafana monitoring stack

Each subdirectory typically contains its own `README.md` and sample configuration files to help you get started with that specific template. For general template usage and best practices, refer to this document.

---

For template-specific details (e.g., available options, example services), see the README in each template directory.
