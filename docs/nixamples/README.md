# nix-mox Template Examples

This directory contains examples of how to use the nix-mox templating system. Each example is a self-contained NixOS configuration that demonstrates a specific feature.

## Examples

- **01-basic-usage**: Demonstrates how to enable a single template.
- **02-custom-options**: Shows how to customize a template with `customOptions`.
- **03-composition**: Illustrates how to use a composite template like `web-app-stack`.
- **04-inheritance**: Shows how a template can inherit from and extend a base template.
- **05-variables**: Demonstrates how to use `templateVariables` for dynamic configuration.
- **06-overrides**: Shows how to override specific files within a template.

## Usage

To use an example, you can import it into your own `configuration.nix`. For example:

```nix
# In your /etc/nixos/configuration.nix
{
  imports = [
    ./path/to/nix-mox/examples/01-basic-usage/configuration.nix
  ];
}
```
