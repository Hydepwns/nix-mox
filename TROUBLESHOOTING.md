# Troubleshooting Guide

## Common Issues and Solutions

### Home Manager Profile Error

**Problem**: Getting error message:
```
/home/hydepwns/.profile: line 1: /etc/profiles/per-user/hydepwns/etc/profile.d/hm-session-vars.sh: No such file or directory
```

**Cause**: Home Manager was previously configured but is no longer installed, leaving a broken profile reference.

**Solution**: Replace the broken profile with a clean one:

```bash
# Back up current profile (optional)
cp ~/.profile ~/.profile.backup

# Create clean profile
cat > ~/.profile << 'EOF'
# Custom profile without Home Manager
export PATH="$HOME/.local/bin:$PATH"

# Add any additional environment variables here
# export EDITOR=nano
# export BROWSER=firefox
EOF
```

**Alternative**: If you want to use Home Manager properly, add it to your NixOS configuration:

1. Add home-manager to your flake inputs
2. Add `inputs.home-manager.nixosModules.default` to imports
3. Configure home-manager users in your configuration.nix

### Build Errors

**Problem**: Flake build fails or nix commands don't work

**Solution**: 
1. Ensure you're in the project root directory
2. Run `nix flake check` to validate the flake
3. Use `nix develop` to enter the development shell
4. Run `make help` to see available commands

### Test Failures

**Problem**: Tests fail or don't run properly

**Solution**:
1. Ensure you're in the nix development shell: `nix develop`
2. Run `make test` for all tests or `nu scripts/test.nu unit` for unit tests
3. Check that all dependencies are available in the development shell

### Storage Guard Failures

**Problem**: Storage guard prevents rebuild

**Solution**:
1. Run `make storage-guard` to see specific issues
2. Fix any storage configuration problems
3. Use `nu scripts/storage.nu fix` to attempt automatic repairs
4. Only reboot after storage guard passes

### Permission Issues

**Problem**: Commands fail due to permissions

**Solution**:
1. Ensure user is in required groups (wheel, etc.)
2. Use `sudo` only for system-level operations
3. Check file permissions in the project directory

### NixOS Rebuild Issues

**Problem**: `nixos-rebuild` fails

**Solution**:
1. **ALWAYS** use `make safe-rebuild` instead of direct `nixos-rebuild`
2. Run `make pre-rebuild` first to validate
3. Use `sudo nixos-rebuild test` to test without applying changes
4. Check system logs with `journalctl -xe` if rebuild fails

## Getting Help

1. Run `make help` to see available commands
2. Check `CLAUDE.md` for comprehensive development guidance
3. Review this troubleshooting guide for common issues
4. Use `--dry-run` flags for safe testing when available

## Prevention

- Always run `make storage-guard` before rebooting
- Use `make pre-rebuild` before system changes
- Keep backups of important configurations
- Test changes with `nixos-rebuild test` first