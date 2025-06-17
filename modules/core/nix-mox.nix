{ config, lib, pkgs, ... }:

let
  cfg = config.services.nix-mox;
in
{
  imports = [
    ./templates/index.nix
    ./error-handling/index.nix
  ];

  options.services.nix-mox = {
    enable = lib.mkEnableOption "Enable nix-mox common scripts and timers";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nix-mox.error-handling
    ];

    # Add nix-mox commands to PATH
    environment.shellInit = ''
      # Add nix-mox commands to PATH
      export PATH="$PATH:${pkgs.nix-mox.error-handling}/bin"
    '';

    # Create systemd timers for scheduled tasks
    systemd.timers = {
      nix-mox-daily = {
        description = "Run nix-mox daily tasks";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };

    # Create systemd services for scheduled tasks
    systemd.services = {
      nix-mox-daily = {
        description = "Run nix-mox daily tasks";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.nix-mox.error-handling}/bin/template-error-handler";
        };
      };
    };
  };
}