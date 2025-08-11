{ config, lib, pkgs, ... }:
let
  # Template configuration
  cfg = config.services.nix-mox.templates;

  # Template definitions
  templates = {
    monitoring = {
      name = "monitoring";
      description = "Monitoring template with Prometheus and Grafana";
      scripts = [
        "prometheus.nix"
        "grafana.nix"
      ];
      dependencies = [
        "prometheus"
        "grafana"
      ];
    };

    windows-gaming = {
      name = "windows-gaming";
      description = "Windows gaming template with Steam and Rust";
      scripts = [
        "install-steam-rust.nu"
        "run-steam-rust.bat"
        "InstallSteamRust.xml"
      ];
      dependencies = [
        "steam"
        "rust"
      ];
      customOptions = {
        steam = {
          installPath = lib.mkOption {
            type = lib.types.str;
            default = "C:\\Program Files (x86)\\Steam";
            description = "Path to install Steam.";
          };
          downloadURL = lib.mkOption {
            type = lib.types.str;
            default = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe";
            description = "URL to download Steam from.";
          };
          silentInstall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to install Steam silently.";
          };
        };
        rust = {
          appId = lib.mkOption {
            type = lib.types.str;
            default = "252490";
            description = "Steam AppID for Rust.";
          };
          installPath = lib.mkOption {
            type = lib.types.str;
            default = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Rust";
            description = "Path to install Rust.";
          };
        };
        monitoring = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable monitoring.";
          };
          logPath = lib.mkOption {
            type = lib.types.str;
            default = "C:\\Program Files (x86)\\Steam\\logs";
            description = "Path to store logs.";
          };
        };
      };
    };

    safe-configuration = {
      name = "safe-configuration";
      description = "Default NixOS configuration template that prevents display issues, integrates with nix-mox tools using the fragment system, and includes comprehensive messaging and communication support.";
      scripts = [
        "flake.nix"
        "configuration.nix"
        "home.nix"
        "README.md"
        "setup.sh"
      ];
      dependencies = [
        "nix"
        "git"
        "vim"
      ];
      customOptions = {
        hostname = {
          type = "string";
          default = "hydebox";
          description = "Hostname for the NixOS system";
        };
        username = {
          type = "string";
          default = "hyde";
          description = "Username for the primary user";
        };
        timezone = {
          type = "string";
          default = "America/New_York";
          description = "Timezone for the system";
        };
        displayManager = {
          type = "enum";
          values = [ "sddm" "gdm" "lightdm" ];
          default = "sddm";
          description = "Display manager to use";
        };
        desktopEnvironment = {
          type = "enum";
          values = [ "gnome" "plasma6" "xfce" "i3" "awesome" ];
          default = "gnome";
          description = "Desktop environment or window manager to use";
        };
        graphicsDriver = {
          type = "enum";
          values = [ "auto" "nvidia" "amdgpu" "intel" ];
          default = "auto";
          description = "Graphics driver to use";
        };
        enableSteam = {
          type = "bool";
          default = true;
          description = "Enable Steam for gaming";
        };
        enableDocker = {
          type = "bool";
          default = true;
          description = "Enable Docker containerization";
        };
        enableSSH = {
          type = "bool";
          default = true;
          description = "Enable SSH server";
        };
        enableFirewall = {
          type = "bool";
          default = true;
          description = "Enable firewall";
        };
        enableMessaging = {
          type = "bool";
          default = true;
          description = "Enable messaging applications (Signal, Telegram, Discord, etc.)";
        };
        enableVideoCalling = {
          type = "bool";
          default = true;
          description = "Enable video calling applications (Zoom, Teams, Skype)";
        };
        enableEmailClients = {
          type = "bool";
          default = true;
          description = "Enable email clients (Thunderbird, Evolution)";
        };
        gitUserName = {
          type = "string";
          default = "Your Name";
          description = "Git user name";
        };
        gitUserEmail = {
          type = "string";
          default = "your.email@example.com";
          description = "Git user email";
        };
      };
    };

    containers = {
      name = "containers";
      description = "Container management template with Docker and LXC";
      scripts = [
        "docker.nix"
        "lxc.nix"
      ];
      dependencies = [
        "docker"
        "lxc"
      ];
    };

    ci-runner = {
      name = "ci-runner";
      description = "CI runner template with parallel execution support";
      scripts = [
        "ci-runner.nix"
        "parallel-execution.nix"
      ];
      dependencies = [
        "git"
        "docker"
      ];
    };

    database-management = {
      name = "database-management";
      description = "Database management template with PostgreSQL and MySQL support";
      scripts = [
        "database-management.nix"
      ];
      dependencies = [
        "postgresql"
        "mysql"
        "prometheus-postgres-exporter"
        "prometheus-mysqld-exporter"
      ];
      customOptions = {
        dbType = {
          type = "enum";
          values = [ "postgresql" "mysql" ];
          default = "postgresql";
          description = "Type of database to manage";
        };
        enableBackups = {
          type = "bool";
          default = true;
          description = "Enable automatic backups";
        };
        backupInterval = {
          type = "string";
          default = "daily";
          description = "Backup interval (daily, weekly, monthly)";
        };
        enableMonitoring = {
          type = "bool";
          default = true;
          description = "Enable monitoring with Prometheus";
        };
      };
    };

    web-server = {
      name = "web-server";
      description = "Web server template with Nginx and Apache support";
      scripts = [
        "web-server.nix"
      ];
      dependencies = [
        "nginx"
        "apacheHttpd"
        "prometheus-nginx-exporter"
        "prometheus-apache-exporter"
        "openssl"
      ];
      customOptions = {
        serverType = {
          type = "enum";
          values = [ "nginx" "apache" ];
          default = "nginx";
          description = "Type of web server to use";
        };
        enableSSL = {
          type = "bool";
          default = false;
          description = "Enable SSL support";
        };
        enableMonitoring = {
          type = "bool";
          default = true;
          description = "Enable monitoring with Prometheus";
        };
        virtualHosts = {
          type = "list";
          description = "List of virtual hosts to configure";
        };
      };
    };

    secure-web-server = {
      name = "secure-web-server";
      extends = "web-server";
      description = "A secure web server with SSL enabled by default.";
      customOptions = {
        enableSSL = {
          default = true;
        };
      };
    };

    load-balancer = {
      name = "load-balancer";
      description = "Load balancer template with HAProxy and Nginx support";
      scripts = [ "load-balancer.nix" ];
      dependencies = [
        "haproxy"
        "nginx"
        "prometheus-haproxy-exporter"
        "prometheus-nginx-exporter"
      ];
      customOptions = {
        lbType = {
          type = "enum";
          values = [ "haproxy" "nginx" ];
          default = "haproxy";
          description = "Type of load balancer to use";
        };
        enableStats = {
          type = "bool";
          default = true;
          description = "Enable statistics page";
        };
        statsUser = {
          type = "string";
          default = "admin";
          description = "Username for statistics page";
        };
        statsPassword = {
          type = "string";
          description = "Password for statistics page";
        };
        enableMonitoring = {
          type = "bool";
          default = true;
          description = "Enable monitoring with Prometheus";
        };
        backends = {
          type = "list";
          description = "List of backends to configure";
        };
      };
    };

    cache-server = {
      name = "cache-server";
      description = "Cache server template with Redis and Memcached support";
      scripts = [ "cache-server.nix" ];
      dependencies = [
        "redis"
        "memcached"
        "prometheus-redis-exporter"
        "prometheus-memcached-exporter"
      ];
      customOptions = {
        cacheType = {
          type = "enum";
          values = [ "redis" "memcached" ];
          default = "redis";
          description = "Type of cache server to use";
        };
        bindAddress = {
          type = "string";
          default = "127.0.0.1";
          description = "Address to bind the cache server to";
        };
        maxMemory = {
          type = "int";
          default = 1024;
          description = "Maximum memory usage in MB";
        };
        maxConnections = {
          type = "int";
          default = 1024;
          description = "Maximum number of connections";
        };
        evictionPolicy = {
          type = "enum";
          values = [ "noeviction" "allkeys-lru" "volatile-lru" "allkeys-random" "volatile-random" "volatile-ttl" ];
          default = "noeviction";
          description = "Memory eviction policy (Redis only)";
        };
        persistence = {
          type = "bool";
          default = true;
          description = "Enable persistence (Redis only)";
        };
        password = {
          type = "string";
          description = "Password for authentication";
        };
        enableMonitoring = {
          type = "bool";
          default = true;
          description = "Enable monitoring with Prometheus";
        };
        enableBackup = {
          type = "bool";
          default = true;
          description = "Enable automated backups";
        };
        backupDir = {
          type = "string";
          default = "/var/lib/cache-server/backups";
          description = "Directory for backups";
        };
        backupRetention = {
          type = "int";
          default = 7;
          description = "Number of days to retain backups";
        };
      };
    };

    message-queue = {
      name = "message-queue";
      description = "Message queue template with RabbitMQ and Kafka support";
      scripts = [ "message-queue.nix" ];
      dependencies = [
        "rabbitmq-server"
        "kafka"
        "prometheus-rabbitmq-exporter"
        "prometheus-kafka-exporter"
        "zookeeper"
      ];
      customOptions = {
        mqType = {
          type = "enum";
          values = [ "rabbitmq" "kafka" ];
          default = "rabbitmq";
          description = "Type of message queue to use";
        };
        username = {
          type = "string";
          default = "admin";
          description = "Username for authentication";
        };
        password = {
          type = "string";
          description = "Password for authentication";
        };
        enableManagement = {
          type = "boolean";
          default = true;
          description = "Enable management interface";
        };
        enableMonitoring = {
          type = "boolean";
          default = true;
          description = "Enable Prometheus monitoring";
        };
        enableBackup = {
          type = "boolean";
          default = true;
          description = "Enable automated backups";
        };
        backupDir = {
          type = "path";
          default = "/var/lib/message-queue/backups";
          description = "Directory for backups";
        };
        backupRetention = {
          type = "integer";
          default = 7;
          description = "Number of days to retain backups";
        };
        memoryLimit = {
          type = "float";
          default = 0.4;
          description = "Memory limit as a fraction of total memory";
        };
        diskLimit = {
          type = "integer";
          default = 1024;
          description = "Disk limit in MB";
        };
        dataDir = {
          type = "path";
          default = "/var/lib/kafka";
          description = "Data directory (Kafka only)";
        };
        partitions = {
          type = "integer";
          default = 1;
          description = "Number of partitions per topic (Kafka only)";
        };
        recoveryThreads = {
          type = "integer";
          default = 1;
          description = "Number of recovery threads per data directory (Kafka only)";
        };
        retentionHours = {
          type = "integer";
          default = 168;
          description = "Log retention period in hours (Kafka only)";
        };
        segmentBytes = {
          type = "integer";
          default = 1073741824;
          description = "Log segment size in bytes (Kafka only)";
        };
        zookeeperConnect = {
          type = "string";
          default = "localhost:2181";
          description = "ZooKeeper connection string (Kafka only)";
        };
        customConfig = {
          type = "attrs";
          default = { };
          description = "Additional message queue configuration";
        };
      };
    };
  };

  # Helper function for template inheritance
  inheritTemplates = finalTemplates:
    let
      resolveInheritance = templateName:
        let
          template = finalTemplates.${templateName};
        in
        if lib.hasAttr "extends" template then
          let
            base = resolveInheritance template.extends;
          in
          lib.recursiveUpdate base template
        else
          template;
    in
    lib.mapAttrs (name: value: resolveInheritance name) finalTemplates;

  # All templates with inheritance resolved
  allTemplates = inheritTemplates templates;

  # Template compositions
  templateCompositions = {
    "web-app-stack" = {
      description = "A full web application stack composed of a web server and a database.";
      templates = [ "web-server" "database-management" ];
    };
  };

  # All available templates and compositions
  allAvailable = allTemplates // templateCompositions;

  # A function to resolve compositions
  resolveTemplates = selected:
    let
      isComposition = name: lib.hasAttr name templateCompositions;
      getCompositionTemplates = name: templateCompositions.${name}.templates;

      resolve = name:
        if isComposition name
        then lib.unique (lib.concatMap resolve (getCompositionTemplates name))
        else [ name ];
    in
    lib.unique (lib.concatMap resolve selected);

  # The list of all final base templates to be installed
  finalTemplates = resolveTemplates cfg.templates;

  # Create template packages
  templatePackages =
    let
      resolvedTemplates = lib.foldl (acc: name: acc // { ${name} = allTemplates.${name}; }) { } finalTemplates;
    in
    lib.mapAttrs
      (name: template:
        pkgs.stdenv.mkDerivation {
          name = "nix-mox-template-${name}";
          version = "1.0.0";
          src = ./../templates/${name};
          buildInputs = with pkgs; [
            jq
            yq
            nix
          ];
          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/share/nix-mox/templates/${name}

            # Generate config.json from customOptions for windows-gaming template
            ${lib.optionalString (name == "windows-gaming") ''
              cat > $out/share/nix-mox/templates/${name}/config.json <<EOF
              ${lib.generators.toJSON {} cfg.customOptions.windows-gaming}
              EOF
            ''}

            # Generate config.json from customOptions for safe-configuration template
            ${lib.optionalString (name == "safe-configuration") ''
              cat > $out/share/nix-mox/templates/${name}/config.json <<EOF
              ${lib.generators.toJSON {} cfg.customOptions.safe-configuration}
              EOF
            ''}

            # Apply overrides first
            ${lib.optionalString (lib.hasAttr name cfg.templateOverrides) ''
              cp -r ${cfg.templateOverrides.${name}}/* $out/share/nix-mox/templates/${name}/
            ''}

            # Copy base template files without overwriting existing (overridden) files
            cp -rn ./_ $out/share/nix-mox/templates/${name}/

            ${lib.optionalString (cfg.templateVariables != {}) ''
              # Substitute variables
              shopt -s globstar
              cd $out/share/nix-mox/templates/${name}/
              for item in **/*; do
                # Only substitute in files, not directories
                if [ -f "$item" ]; then
                  substituteInPlace "$item" \
                    ${lib.concatStringsSep " \\\n                    " (lib.mapAttrsToList (n: v: "--replace '@${n}@' '${v}'") cfg.templateVariables)}
                fi
              done
              cd -
            ''}
            # Create template script
            cat > $out/bin/nix-mox-template-${name} <<EOF
            #!/bin/sh
            set -e

            # Source error handling
            . ${pkgs.nix-mox.error-handling}/bin/template-error-handler

            # Template configuration
            TEMPLATE_DIR="$out/share/nix-mox/templates/${name}"
            TEMPLATE_NAME="${template.name}"
            TEMPLATE_DESC="${template.description}"

            # Check dependencies
            for dep in ${lib.concatStringsSep " " template.dependencies}; do
              if ! command -v \$dep >/dev/null 2>&1; then
                ${lib.getAttr "handleError" pkgs.nix-mox.error-handling} 5 "Dependency \$dep not found"
              fi
            done

            # Execute template scripts
            for script in ${lib.concatStringsSep " " template.scripts}; do
              if [ -f "\$TEMPLATE_DIR/\$script" ]; then
                ${lib.getAttr "logMessage" pkgs.nix-mox.error-handling} "INFO" "Executing \$script"
                nix-instantiate --eval "\$TEMPLATE_DIR/\$script"
              else
                ${lib.getAttr "logMessage" pkgs.nix-mox.error-handling} "WARN" "Script \$script not found"
              fi
            done

            ${lib.getAttr "logMessage" pkgs.nix-mox.error-handling} "INFO" "Template ${template.name} completed successfully"
            EOF

            chmod +x $out/bin/nix-mox-template-${name}
          '';
        }
      )
      resolvedTemplates;

  # Update test fixture references
  testFixtures = {
    nixos = ./../scripts/testing/fixtures/nixos/default.nix;
cachix = ./../scripts/testing/fixtures/cachix/default.nix;
utils = ./../scripts/testing/fixtures/utils/default.nix;
  };
in
{
  options.services.nix-mox.templates = {
    enable = lib.mkEnableOption "Enable nix-mox templates";
    templates = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (lib.attrNames allAvailable));
      default = lib.attrNames templates;
      description = "List of templates or compositions to enable.";
    };
    customOptions = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Custom options for templates";
    };
    templateVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Global variables to be substituted in all template files. Use @key@ syntax in files.";
      example = { domain = "example.com"; user = "admin"; };
    };
    templateOverrides = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Override files in a template. The key is the template name and the value is the path to the directory with override files.";
      example = { "web-server" = ./my-web-server-overrides; };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = (lib.map (name: templatePackages.${name}) finalTemplates);

    # Add template commands to nix-mox
    environment.shellInit = ''
      # Add template commands to nix-mox
      for template in ${lib.concatStringsSep " " finalTemplates}; do
        alias nix-mox-template-$template="nix-mox-template-$template"
      done
    '';

    # Create systemd services for templates that need them
    systemd.services = lib.mkMerge [
      (lib.mkIf (lib.elem "database-management" finalTemplates) {
        "database-${cfg.customOptions.database-management.dbType or "postgresql"}" = {
          description = "Database management service";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${templatePackages.database-management}/bin/nix-mox-template-database-management";
          };
        };
      })
      (lib.mkIf (lib.elem "web-server" finalTemplates) {
        "web-${cfg.customOptions.web-server.serverType or "nginx"}" = {
          description = "Web server service";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${templatePackages.web-server}/bin/nix-mox-template-web-server";
          };
        };
      })
    ];

    # Add template documentation
    documentation.nixos.extraModuleSources = [ ./../templates ];
  };
}
