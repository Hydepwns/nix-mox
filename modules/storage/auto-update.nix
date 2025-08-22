{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.storageAutoUpdate;
  
  updateStorageScript = pkgs.writeShellScriptBin "update-storage-config" ''
    set -euo pipefail
    
    echo "🔍 Detecting current storage configuration..."
    
    # Get current root device
    ROOT_DEVICE=$(findmnt -n -o SOURCE /)
    echo "Current root device: $ROOT_DEVICE"
    
    # Get actual UUID
    if [[ "$ROOT_DEVICE" =~ ^/dev/ ]]; then
      ACTUAL_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")
      ACTUAL_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_DEVICE")
      echo "Actual UUID: $ACTUAL_UUID"
      echo "Actual PARTUUID: $ACTUAL_PARTUUID"
    else
      echo "⚠️  Root device is not a block device, skipping UUID update"
      exit 0
    fi
    
    # Read current hardware-configuration.nix
    HARDWARE_CONFIG="${cfg.hardwareConfigPath}"
    
    if [ ! -f "$HARDWARE_CONFIG" ]; then
      echo "❌ Hardware configuration not found at $HARDWARE_CONFIG"
      exit 1
    fi
    
    # Extract configured UUID from hardware-configuration.nix
    CONFIGURED_UUID=$(grep -oP 'by-uuid/\K[a-f0-9-]+' "$HARDWARE_CONFIG" | head -1 || true)
    
    if [ -z "$CONFIGURED_UUID" ]; then
      echo "⚠️  No UUID found in hardware configuration, checking for other identifiers..."
      
      # Check for by-label or by-partuuid
      if grep -q "by-label\|by-partuuid" "$HARDWARE_CONFIG"; then
        echo "Found alternative identifiers, skipping UUID update"
        exit 0
      fi
    fi
    
    # Compare UUIDs
    if [ "$CONFIGURED_UUID" = "$ACTUAL_UUID" ]; then
      echo "✅ Storage configuration is up to date"
      exit 0
    fi
    
    echo "⚠️  UUID mismatch detected!"
    echo "  Configured: $CONFIGURED_UUID"
    echo "  Actual:     $ACTUAL_UUID"
    
    # Create backup
    BACKUP_FILE="$HARDWARE_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$HARDWARE_CONFIG" "$BACKUP_FILE"
    echo "📦 Created backup: $BACKUP_FILE"
    
    # Update the configuration
    echo "🔧 Updating hardware configuration..."
    sed -i "s|by-uuid/$CONFIGURED_UUID|by-uuid/$ACTUAL_UUID|g" "$HARDWARE_CONFIG"
    
    # Verify the update
    NEW_UUID=$(grep -oP 'by-uuid/\K[a-f0-9-]+' "$HARDWARE_CONFIG" | head -1 || true)
    if [ "$NEW_UUID" = "$ACTUAL_UUID" ]; then
      echo "✅ Successfully updated storage configuration"
      
      # Also update any swap references if present
      if [ -f /proc/swaps ]; then
        SWAP_DEVICES=$(awk 'NR>1 {print $1}' /proc/swaps | grep "^/dev/" || true)
        for SWAP in $SWAP_DEVICES; do
          SWAP_UUID=$(blkid -s UUID -o value "$SWAP" 2>/dev/null || true)
          if [ -n "$SWAP_UUID" ]; then
            echo "🔄 Updating swap UUID: $SWAP_UUID"
            sed -i "s|by-uuid/[a-f0-9-]\{8\}-[a-f0-9-]\{4\}-[a-f0-9-]\{4\}-[a-f0-9-]\{4\}-[a-f0-9-]\{12\}|by-uuid/$SWAP_UUID|g" "$HARDWARE_CONFIG"
          fi
        done
      fi
      
      echo "📝 Configuration updated. Review changes:"
      echo "diff $BACKUP_FILE $HARDWARE_CONFIG"
    else
      echo "❌ Update failed, restoring backup..."
      mv "$BACKUP_FILE" "$HARDWARE_CONFIG"
      exit 1
    fi
  '';

  validateStorageScript = pkgs.writeShellScriptBin "validate-storage-config" ''
    set -euo pipefail
    
    echo "🔍 Validating storage configuration..."
    
    HARDWARE_CONFIG="${cfg.hardwareConfigPath}"
    ERRORS=0
    
    # Check all UUID references
    UUIDS=$(grep -oP 'by-uuid/\K[a-f0-9-]+' "$HARDWARE_CONFIG" 2>/dev/null || true)
    
    for UUID in $UUIDS; do
      if ! blkid -U "$UUID" >/dev/null 2>&1; then
        echo "❌ UUID not found: $UUID"
        ERRORS=$((ERRORS + 1))
      else
        DEVICE=$(blkid -U "$UUID")
        echo "✅ UUID $UUID -> $DEVICE"
      fi
    done
    
    # Check PARTUUID references
    PARTUUIDS=$(grep -oP 'by-partuuid/\K[a-f0-9-]+' "$HARDWARE_CONFIG" 2>/dev/null || true)
    
    for PARTUUID in $PARTUUIDS; do
      if ! blkid -t PARTUUID="$PARTUUID" >/dev/null 2>&1; then
        echo "❌ PARTUUID not found: $PARTUUID"
        ERRORS=$((ERRORS + 1))
      else
        DEVICE=$(blkid -t PARTUUID="$PARTUUID" -o device)
        echo "✅ PARTUUID $PARTUUID -> $DEVICE"
      fi
    done
    
    # Check labels
    LABELS=$(grep -oP 'by-label/\K[^"]+' "$HARDWARE_CONFIG" 2>/dev/null || true)
    
    for LABEL in $LABELS; do
      if ! blkid -L "$LABEL" >/dev/null 2>&1; then
        echo "❌ Label not found: $LABEL"
        ERRORS=$((ERRORS + 1))
      else
        DEVICE=$(blkid -L "$LABEL")
        echo "✅ Label $LABEL -> $DEVICE"
      fi
    done
    
    if [ $ERRORS -gt 0 ]; then
      echo "❌ Found $ERRORS storage configuration errors"
      exit 1
    else
      echo "✅ All storage identifiers are valid"
      exit 0
    fi
  '';

in {
  options.services.storageAutoUpdate = {
    enable = mkEnableOption "automatic storage configuration updates";
    
    hardwareConfigPath = mkOption {
      type = types.path;
      default = "/etc/nixos/hardware-configuration.nix";
      description = "Path to the hardware configuration file";
    };
    
    autoUpdate = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically update UUIDs before rebuild";
    };
    
    validateOnly = mkOption {
      type = types.bool;
      default = false;
      description = "Only validate, don't auto-update";
    };
  };
  
  config = mkIf cfg.enable {
    environment.systemPackages = [
      updateStorageScript
      validateStorageScript
    ];
    
    # Create a pre-rebuild activation script
    system.activationScripts.storageCheck = mkIf cfg.autoUpdate ''
      echo "🔍 Checking storage configuration before activation..."
      
      if [ -z "''${NIXOS_SKIP_STORAGE_CHECK:-}" ]; then
        if ${validateStorageScript}/bin/validate-storage-config; then
          echo "✅ Storage configuration is valid"
        else
          if [ "''${cfg.validateOnly}" != "true" ]; then
            echo "🔧 Attempting automatic fix..."
            ${updateStorageScript}/bin/update-storage-config
          else
            echo "❌ Storage validation failed. Run 'update-storage-config' to fix."
            exit 1
          fi
        fi
      else
        echo "⚠️  Skipping storage check (NIXOS_SKIP_STORAGE_CHECK is set)"
      fi
    '';
    
    # Add systemd service for periodic checks
    systemd.services.storage-config-check = {
      description = "Check and update storage configuration";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${validateStorageScript}/bin/validate-storage-config";
      };
    };
    
    systemd.timers.storage-config-check = mkIf cfg.autoUpdate {
      description = "Periodic storage configuration check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1d";
      };
    };
  };
}