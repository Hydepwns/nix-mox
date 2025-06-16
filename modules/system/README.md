# System Modules

This directory contains system-level configurations for hardware and networking.

## Structure

- `networking/`: Network configuration modules
- `hardware/`: Hardware-specific configuration modules

## Usage

These modules are typically used in system-level configurations and should be imported early in the configuration process.

Example:

```nix
{
  imports = [
    nix-mox.nixosModules.system.networking
    nix-mox.nixosModules.system.hardware
  ];
}
```
