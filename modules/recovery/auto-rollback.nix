# Auto-rollback module for system recovery
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.boot.autoRollback;
  
  # Rollback detection script
  rollbackScript = pkgs.writeScript "auto-rollback" ''
    #!${pkgs.bash}/bin/bash
    
    BOOT_COUNT_FILE="/var/lib/boot-count"
    MAX_ATTEMPTS=${toString cfg.maxAttempts}
    
    # Initialize or increment boot counter
    if [ -f "$BOOT_COUNT_FILE" ]; then
      BOOT_COUNT=$(cat "$BOOT_COUNT_FILE")
      BOOT_COUNT=$((BOOT_COUNT + 1))
    else
      BOOT_COUNT=1
    fi
    
    echo "$BOOT_COUNT" > "$BOOT_COUNT_FILE"
    
    # Check if we should rollback
    if [ "$BOOT_COUNT" -gt "$MAX_ATTEMPTS" ]; then
      echo "❌ Boot failed $MAX_ATTEMPTS times, rolling back to previous generation..."
      
      # Get previous generation
      CURRENT_GEN=$(readlink /nix/var/nix/profiles/system)
      PREV_GEN=$(readlink /nix/var/nix/profiles/system-$(($(basename $CURRENT_GEN | sed 's/[^0-9]//g') - 1))-link)
      
      if [ -n "$PREV_GEN" ] && [ -e "$PREV_GEN" ]; then
        # Switch to previous generation
        nix-env --profile /nix/var/nix/profiles/system --set "$PREV_GEN"
        /nix/var/nix/profiles/system/bin/switch-to-configuration boot
        
        # Reset boot counter
        echo "0" > "$BOOT_COUNT_FILE"
        
        # Notify user
        wall "System rolled back to previous generation due to repeated boot failures"
        
        # Reboot to apply
        systemctl reboot
      else
        echo "⚠️  No previous generation available for rollback"
      fi
    fi
  '';
  
  # Success marker script
  successScript = pkgs.writeScript "mark-boot-success" ''
    #!${pkgs.bash}/bin/bash
    
    BOOT_COUNT_FILE="/var/lib/boot-count"
    
    # Reset boot counter on successful boot
    echo "0" > "$BOOT_COUNT_FILE"
    echo "✅ Boot successful, counter reset"
  '';
in
{
  options.boot.autoRollback = {
    enable = mkEnableOption "automatic rollback on boot failure";
    
    maxAttempts = mkOption {
      type = types.int;
      default = 3;
      description = "Maximum boot attempts before rollback";
    };
    
    timeout = mkOption {
      type = types.int;
      default = 300;  # 5 minutes
      description = "Seconds to wait before marking boot as successful";
    };
    
    displayManagerCheck = mkEnableOption "check if display manager started successfully";
    
    networkCheck = mkEnableOption "check if network is available";
    
    customChecks = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Custom systemd units that must be active for successful boot";
    };
  };

  config = mkIf cfg.enable {
    # Early boot rollback check
    boot.initrd.postMountCommands = ''
      ${rollbackScript}
    '';
    
    # Service to detect successful boot
    systemd.services.boot-success-marker = {
      description = "Mark boot as successful";
      after = [ "multi-user.target" ]
        ++ optional cfg.displayManagerCheck "display-manager.service"
        ++ optional cfg.networkCheck "network-online.target"
        ++ cfg.customChecks;
      
      wants = [ "multi-user.target" ]
        ++ optional cfg.displayManagerCheck "display-manager.service"
        ++ optional cfg.networkCheck "network-online.target";
      
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = successScript;
      };
    };
    
    # Timer to mark boot successful after timeout
    systemd.timers.boot-success-timer = {
      description = "Timer to mark boot as successful";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnBootSec = "${toString cfg.timeout}s";
        Unit = "boot-success-marker.service";
      };
    };
    
    # Emergency recovery shell
    systemd.services.emergency-recovery = {
      description = "Emergency recovery shell";
      
      serviceConfig = {
        Type = "idle";
        ExecStart = pkgs.writeScriptBin "emergency-recovery" ''
          #!${pkgs.bash}/bin/bash
          echo "🚨 EMERGENCY RECOVERY MODE"
          echo ""
          echo "System has been rolled back due to boot failures."
          echo "You are now in recovery mode."
          echo ""
          echo "Available commands:"
          echo "  nixos-rebuild list-generations  - List all generations"
          echo "  nixos-rebuild switch --rollback - Rollback to previous"
          echo "  nixos-rebuild boot              - Rebuild boot config"
          echo ""
          echo "Press Enter to continue to recovery shell..."
          read
          exec ${pkgs.bash}/bin/bash
        '';
        StandardInput = "tty";
        StandardOutput = "tty";
        TTYPath = "/dev/tty1";
        TTYReset = true;
        TTYVHangup = true;
      };
      
      # Only start if rollback occurred
      unitConfig = {
        ConditionPathExists = "/var/lib/boot-rollback-occurred";
      };
    };
    
    # Create state directory
    systemd.tmpfiles.rules = [
      "d /var/lib 0755 root root -"
      "f /var/lib/boot-count 0644 root root -"
    ];
    
    # Helper commands
    environment.systemPackages = with pkgs; [
      (writeScriptBin "rollback-status" ''
        #!${pkgs.bash}/bin/bash
        BOOT_COUNT_FILE="/var/lib/boot-count"
        
        if [ -f "$BOOT_COUNT_FILE" ]; then
          COUNT=$(cat "$BOOT_COUNT_FILE")
          echo "Boot attempt: $COUNT / ${toString cfg.maxAttempts}"
          
          if [ "$COUNT" -eq 0 ]; then
            echo "✅ System is stable"
          else
            echo "⚠️  System is being tested (will rollback after ${toString cfg.maxAttempts} failures)"
          fi
        else
          echo "✅ Auto-rollback not active"
        fi
      '')
      
      (writeScriptBin "rollback-reset" ''
        #!${pkgs.bash}/bin/bash
        echo "0" > /var/lib/boot-count
        echo "✅ Boot counter reset"
      '')
      
      (writeScriptBin "rollback-test" ''
        #!${pkgs.bash}/bin/bash
        echo "🧪 Testing rollback mechanism..."
        echo "${toString cfg.maxAttempts}" > /var/lib/boot-count
        echo "⚠️  Next boot will trigger rollback!"
        echo "Run 'rollback-reset' to cancel"
      '')
    ];
    
    # Boot counting in kernel parameters
    boot.kernelParams = [ "systemd.setenv=BOOT_COUNT_ENABLED=1" ];
  };
}