{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.sessionManagement;
in
{
  options.services.sessionManagement = {
    enable = mkEnableOption "Enhanced session management for preventing reboot issues";
    
    ensureRebootCapability = mkOption {
      type = types.bool;
      default = true;
      description = "Ensure reboot/shutdown works from GUI after rebuilds";
    };
    
    preventServiceRestartIssues = mkOption {
      type = types.bool;
      default = true;
      description = "Prevent service restart issues that break session management";
    };
  };

  config = mkIf cfg.enable {
    # Ensure PolicyKit is properly configured
    security.polkit.enable = true;
    
    # Add rules for wheel group to perform power actions without issues
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        // Allow wheel group users to perform power management actions
        if (subject.isInGroup("wheel")) {
          var actions = [
            "org.freedesktop.login1.power-off",
            "org.freedesktop.login1.power-off-multiple-sessions",
            "org.freedesktop.login1.reboot",
            "org.freedesktop.login1.reboot-multiple-sessions",
            "org.freedesktop.login1.suspend",
            "org.freedesktop.login1.suspend-multiple-sessions",
            "org.freedesktop.login1.hibernate",
            "org.freedesktop.login1.hibernate-multiple-sessions",
            "org.freedesktop.login1.set-wall-message"
          ];
          
          if (actions.indexOf(action.id) !== -1) {
            return polkit.Result.YES;
          }
        }
        
        // Allow active sessions to reboot/shutdown without password
        if ((action.id == "org.freedesktop.login1.reboot" ||
             action.id == "org.freedesktop.login1.power-off" ||
             action.id == "org.freedesktop.login1.suspend" ||
             action.id == "org.freedesktop.login1.hibernate") &&
            subject.active && subject.local) {
          return polkit.Result.YES;
        }
      });
    '';
    
    # Prevent service restart issues during rebuilds
    systemd.services = mkIf cfg.preventServiceRestartIssues {
      # Don't restart these critical services during rebuild
      systemd-logind.restartIfChanged = false;
      systemd-logind.stopIfChanged = false;
      systemd-logind.restartTriggers = [];
      
      polkit.restartIfChanged = false;
      polkit.stopIfChanged = false;
      polkit.restartTriggers = [];
      
      display-manager.restartIfChanged = false;
      display-manager.stopIfChanged = false;
    };
    
    # Ensure D-Bus is properly configured
    services.dbus.enable = true;
    services.dbus.packages = with pkgs; [ 
      dconf
      gcr
      gnome-settings-daemon
    ];
    
    # Add systemd user services for session management
    systemd.user.services = {
      # Ensure PolicyKit authentication agent is running for GUI
      polkit-kde-authentication-agent = mkIf config.services.xserver.desktopManager.plasma5.enable {
        description = "PolicyKit Authentication Agent";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
      
      polkit-kde-authentication-agent-plasma6 = mkIf config.services.desktopManager.plasma6.enable {
        description = "PolicyKit Authentication Agent for Plasma 6";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
    
    # Add warning for common issues
    warnings = 
      (if config.services.desktopManager.plasma6.enable && !cfg.preventServiceRestartIssues then
        [ "Plasma 6 is enabled but service restart prevention is disabled. This may cause reboot issues after rebuilds." ]
      else []) ++
      (if !config.security.polkit.enable then
        [ "PolicyKit is disabled. This will cause issues with GUI reboot/shutdown functionality." ]
      else []);
    
    # Add assertions for critical configuration
    assertions = [
      {
        assertion = config.security.polkit.enable;
        message = "PolicyKit must be enabled for proper session management";
      }
      {
        assertion = config.services.dbus.enable;
        message = "D-Bus must be enabled for session management";
      }
    ];
  };
}