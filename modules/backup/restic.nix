# Restic backup module for automated system backups
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.backup;
  
  # Backup script
  backupScript = pkgs.writeScriptBin "nixos-backup" ''
    #!/bin/sh
    set -e
    
    echo "🔵 Starting NixOS backup..."
    
    # Ensure backup directory exists
    mkdir -p ${cfg.repository}
    
    # Initialize repository if needed
    if [ ! -f ${cfg.repository}/config ]; then
      echo "📦 Initializing backup repository..."
      ${pkgs.restic}/bin/restic init \
        --repo ${cfg.repository} \
        --password-file ${cfg.passwordFile}
    fi
    
    # Run backup
    echo "📤 Backing up system..."
    ${pkgs.restic}/bin/restic backup \
      --repo ${cfg.repository} \
      --password-file ${cfg.passwordFile} \
      --exclude-caches \
      --one-file-system \
      --tag "nixos" \
      --tag "$(date +%Y-%m-%d)" \
      ${concatMapStringsSep " " (x: "--exclude '${x}'") cfg.exclude} \
      ${concatStringsSep " " cfg.paths}
    
    # Prune old backups
    if [ "${toString cfg.prune.enable}" = "true" ]; then
      echo "🧹 Pruning old backups..."
      ${pkgs.restic}/bin/restic forget \
        --repo ${cfg.repository} \
        --password-file ${cfg.passwordFile} \
        --prune \
        --keep-daily ${toString cfg.prune.keepDaily} \
        --keep-weekly ${toString cfg.prune.keepWeekly} \
        --keep-monthly ${toString cfg.prune.keepMonthly} \
        --keep-yearly ${toString cfg.prune.keepYearly}
    fi
    
    # Check backup integrity
    if [ "${toString cfg.check.enable}" = "true" ]; then
      echo "🔍 Checking backup integrity..."
      ${pkgs.restic}/bin/restic check \
        --repo ${cfg.repository} \
        --password-file ${cfg.passwordFile} \
        ${optionalString cfg.check.readData "--read-data"}
    fi
    
    echo "✅ Backup completed successfully!"
  '';
  
  # Restore script
  restoreScript = pkgs.writeScriptBin "nixos-restore" ''
    #!/bin/sh
    set -e
    
    SNAPSHOT="$1"
    TARGET="$2"
    
    if [ -z "$SNAPSHOT" ] || [ -z "$TARGET" ]; then
      echo "Usage: nixos-restore <snapshot-id> <target-directory>"
      echo ""
      echo "List snapshots with: restic snapshots --repo ${cfg.repository}"
      exit 1
    fi
    
    echo "🔵 Starting NixOS restore..."
    echo "📥 Restoring snapshot $SNAPSHOT to $TARGET"
    
    ${pkgs.restic}/bin/restic restore \
      --repo ${cfg.repository} \
      --password-file ${cfg.passwordFile} \
      --target "$TARGET" \
      "$SNAPSHOT"
    
    echo "✅ Restore completed successfully!"
  '';
in
{
  options.services.backup = {
    enable = mkEnableOption "automated backup with restic";
    
    repository = mkOption {
      type = types.str;
      default = "/var/backup/restic";
      description = "Path to the restic repository";
    };
    
    passwordFile = mkOption {
      type = types.path;
      default = "/etc/nixos/secrets/backup-password";
      description = "Path to file containing the repository password";
    };
    
    paths = mkOption {
      type = types.listOf types.path;
      default = [
        "/home"
        "/etc/nixos"
        "/var/lib"
        "/root"
      ];
      description = "Paths to backup";
    };
    
    exclude = mkOption {
      type = types.listOf types.str;
      default = [
        "/home/*/.cache"
        "/home/*/.local/share/Trash"
        "/home/*/Downloads"
        "/home/*/.steam/steamapps"
        "/home/*/.local/share/lutris"
        "/home/*/.wine"
        "/home/*/.config/heroic/tools"
        "*.tmp"
        "*.temp"
        "*.swp"
        "*.swo"
        "*~"
        ".DS_Store"
        "node_modules"
        "__pycache__"
        ".pytest_cache"
        ".mypy_cache"
      ];
      description = "Patterns to exclude from backup";
    };
    
    schedule = mkOption {
      type = types.str;
      default = "daily";
      description = "Backup schedule (systemd timer format)";
    };
    
    prune = {
      enable = mkEnableOption "automatic pruning of old backups";
      
      keepDaily = mkOption {
        type = types.int;
        default = 7;
        description = "Number of daily backups to keep";
      };
      
      keepWeekly = mkOption {
        type = types.int;
        default = 4;
        description = "Number of weekly backups to keep";
      };
      
      keepMonthly = mkOption {
        type = types.int;
        default = 6;
        description = "Number of monthly backups to keep";
      };
      
      keepYearly = mkOption {
        type = types.int;
        default = 2;
        description = "Number of yearly backups to keep";
      };
    };
    
    check = {
      enable = mkEnableOption "backup integrity checking";
      
      readData = mkOption {
        type = types.bool;
        default = false;
        description = "Also read and check data blob integrity (slow)";
      };
      
      schedule = mkOption {
        type = types.str;
        default = "weekly";
        description = "Check schedule (systemd timer format)";
      };
    };
    
    remoteBackup = {
      enable = mkEnableOption "remote backup to cloud storage";
      
      type = mkOption {
        type = types.enum [ "s3" "b2" "azure" "gcs" "sftp" "rest" ];
        default = "s3";
        description = "Remote backup type";
      };
      
      repository = mkOption {
        type = types.str;
        default = "";
        description = "Remote repository URL";
      };
      
      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "File with environment variables for remote access";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install restic
    environment.systemPackages = [
      pkgs.restic
      backupScript
      restoreScript
    ];
    
    # Backup service
    systemd.services.nixos-backup = {
      description = "NixOS system backup";
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${backupScript}/bin/nixos-backup";
        StandardOutput = "journal";
        StandardError = "journal";
        
        # Security hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [ cfg.repository "/var/log" ];
        NoNewPrivileges = true;
        
        # Performance
        Nice = 19;
        IOSchedulingClass = "idle";
        CPUSchedulingPolicy = "idle";
      };
      
      environment = mkIf cfg.remoteBackup.enable {
        RESTIC_REPOSITORY = cfg.remoteBackup.repository;
      };
      
      path = [ pkgs.openssh pkgs.rclone ];
    };
    
    # Backup timer
    systemd.timers.nixos-backup = {
      description = "NixOS backup timer";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
    
    # Check service
    systemd.services.nixos-backup-check = mkIf cfg.check.enable {
      description = "Check NixOS backup integrity";
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.restic}/bin/restic check --repo ${cfg.repository} --password-file ${cfg.passwordFile} ${optionalString cfg.check.readData "--read-data"}";
        StandardOutput = "journal";
        StandardError = "journal";
        Nice = 19;
      };
    };
    
    # Check timer
    systemd.timers.nixos-backup-check = mkIf cfg.check.enable {
      description = "NixOS backup check timer";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = cfg.check.schedule;
        Persistent = true;
        RandomizedDelaySec = "2h";
      };
    };
    
    # Helper commands
    environment.shellAliases = {
      backup-status = "restic snapshots --repo ${cfg.repository} --password-file ${cfg.passwordFile}";
      backup-list = "restic ls --repo ${cfg.repository} --password-file ${cfg.passwordFile} latest";
      backup-mount = "restic mount --repo ${cfg.repository} --password-file ${cfg.passwordFile}";
      backup-stats = "restic stats --repo ${cfg.repository} --password-file ${cfg.passwordFile}";
    };
    
    # Create backup directory
    systemd.tmpfiles.rules = [
      "d ${cfg.repository} 0700 root root -"
    ];
    
    # Documentation
    environment.etc."backup-readme.md".text = ''
      # NixOS Backup System
      
      ## Quick Commands
      
      - Manual backup: `sudo nixos-backup`
      - List snapshots: `backup-status`
      - Restore: `sudo nixos-restore <snapshot-id> <target-dir>`
      - Mount backup: `backup-mount /mnt/backup`
      - Check integrity: `sudo restic check --repo ${cfg.repository}`
      
      ## Backup Schedule
      
      Automatic backups run: ${cfg.schedule}
      
      ## Included Paths
      ${concatMapStringsSep "\n" (p: "- ${p}") cfg.paths}
      
      ## Excluded Patterns
      ${concatMapStringsSep "\n" (p: "- ${p}") cfg.exclude}
      
      ## Retention Policy
      - Daily: ${toString cfg.prune.keepDaily} backups
      - Weekly: ${toString cfg.prune.keepWeekly} backups
      - Monthly: ${toString cfg.prune.keepMonthly} backups
      - Yearly: ${toString cfg.prune.keepYearly} backups
      
      ## Recovery Procedure
      
      1. Boot from NixOS live USB
      2. Mount your disk
      3. Restore configuration:
         ```
         nixos-restore <snapshot> /mnt/etc/nixos
         ```
      4. Restore home:
         ```
         nixos-restore <snapshot> /mnt/home
         ```
      5. Rebuild system:
         ```
         nixos-rebuild boot --root /mnt
         ```
    '';
  };
}