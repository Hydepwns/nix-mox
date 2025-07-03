# Plasma 6 & Kitty Terminal Setup

## Default Desktop Environment

- KDE Plasma 6 is the default desktop environment for all templates.
- SDDM is the default display manager for Plasma 6.
- GNOME is available as an optional alternative (see template comments).

## Default Terminal Emulator

- Kitty is installed system-wide and set as the default terminal for all users.
- To customize Kitty per-user, use the `programs.kitty` block in your home-manager config.
- You can further set Kitty as the default terminal in Plasma System Settings → Applications → Default Applications → Terminal Emulator.

## Wayland Support

- SDDM is configured to enable Wayland sessions by default for Plasma 6.
- For best results, ensure your GPU supports Wayland and hardware acceleration is enabled.

## Hardware Acceleration

- Hardware OpenGL acceleration is enabled by default:
  - `hardware.opengl.enable = true;`
  - `hardware.opengl.driSupport = true;`
  - `hardware.opengl.driSupport32Bit = true;`

## Cleaning Up Old Users/Groups

- If you previously used LightDM or GDM, ensure old users/groups (e.g., `lightdm`, `gdm`) are removed from `/etc/passwd` and `/etc/group`.
- The NixOS switch process should remove these automatically, but you can check manually if needed.

## Reproducibility

- Flake inputs are pinned for reproducibility. Update with:

  ```bash
  nix flake update
  nix flake check
  ```

- Always test your configuration after updating inputs.

## Migration Notes

- Plasma 6 replaces Plasma 5 and is Wayland-first. Most modern hardware is supported out of the box.
- If you encounter issues with legacy applications, try running them under XWayland or use the fallback X11 session from SDDM.

## Further Customization

- See your `config/personal/hydepwns.nix` for user-level Kitty and Plasma customizations.
- For more advanced tweaks, refer to the [NixOS Plasma 6 documentation](https://search.nixos.org/options?channel=unstable&query=plasma6) and [Kitty documentation](https://sw.kovidgoyal.net/kitty/).
