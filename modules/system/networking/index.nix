{ pkgs, config, lib, ... }:

let
  # NetworkManager configuration (default)
  networkmanager = { config, lib, pkgs, ... }: {
    options.networking = {
      networkmanager = {
        enable = lib.mkEnableOption "Enable NetworkManager";
        wifi.backend = lib.mkOption {
          type = lib.types.enum [ "wpa_supplicant" "iwd" ];
          default = "wpa_supplicant";
          description = "WiFi backend to use";
        };
        ethernet = {
          enable = lib.mkEnableOption "Enable Ethernet support";
          wakeOnLan = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Wake-on-LAN for Ethernet";
          };
        };
      };
      firewall = {
        enable = lib.mkEnableOption "Enable firewall";
        allowedTCPPorts = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "Allowed TCP ports";
        };
        allowedUDPPorts = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "Allowed UDP ports";
        };
        allowedTCPPortRanges = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              from = lib.mkOption { type = lib.types.port; };
              to = lib.mkOption { type = lib.types.port; };
            };
          });
          default = [ ];
          description = "Allowed TCP port ranges";
        };
      };
      vpn = {
        enable = lib.mkEnableOption "Enable VPN support";
        openvpn = {
          enable = lib.mkEnableOption "Enable OpenVPN";
          configs = lib.mkOption {
            type = lib.types.listOf lib.types.path;
            default = [ ];
            description = "OpenVPN configuration files";
          };
        };
        wireguard = {
          enable = lib.mkEnableOption "Enable WireGuard";
          interfaces = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                ips = lib.mkOption { type = lib.types.listOf lib.types.str; };
                privateKey = lib.mkOption { type = lib.types.str; };
                peers = lib.mkOption {
                  type = lib.types.listOf (lib.types.submodule {
                    options = {
                      publicKey = lib.mkOption { type = lib.types.str; };
                      allowedIPs = lib.mkOption { type = lib.types.listOf lib.types.str; };
                      endpoint = lib.mkOption { type = lib.types.str; };
                    };
                  });
                };
              };
            });
            default = { };
            description = "WireGuard interfaces";
          };
        };
      };
      dns = {
        enable = lib.mkEnableOption "Enable DNS configuration";
        nameservers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "1.1.1.1" "8.8.8.8" ];
          description = "DNS nameservers";
        };
        search = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "DNS search domains";
        };
        localResolver = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable local DNS resolver (systemd-resolved)";
        };
      };
      proxy = {
        enable = lib.mkEnableOption "Enable proxy configuration";
        httpProxy = lib.mkOption {
          type = lib.types.str;
          description = "HTTP proxy URL";
        };
        httpsProxy = lib.mkOption {
          type = lib.types.str;
          description = "HTTPS proxy URL";
        };
        noProxy = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "localhost" "127.0.0.1" ];
          description = "Hosts that should not use proxy";
        };
      };
    };

    config = let
      cfg = config.networking;
    in {
      # Default to NetworkManager
      networking = {
        networkmanager = lib.mkDefault {
          enable = true;
          wifi.backend = cfg.networkmanager.wifi.backend;
        };

        # Firewall configuration
        firewall = lib.mkIf cfg.firewall.enable {
          enable = true;
          allowedTCPPorts = cfg.firewall.allowedTCPPorts;
          allowedUDPPorts = cfg.firewall.allowedUDPPorts;
          allowedTCPPortRanges = cfg.firewall.allowedTCPPortRanges;
        };

        # DNS configuration
        nameservers = lib.mkIf cfg.dns.enable cfg.dns.nameservers;
        search = lib.mkIf cfg.dns.enable cfg.dns.search;
      };

      # Local DNS resolver
      services.resolved = lib.mkIf (cfg.dns.enable && cfg.dns.localResolver) {
        enable = true;
        dns = cfg.dns.nameservers;
        domains = cfg.dns.search;
      };

      # VPN configurations
      services.openvpn = lib.mkIf (cfg.vpn.enable && cfg.vpn.openvpn.enable) {
        servers = lib.mapAttrs'
          (name: config: lib.nameValuePair name { config = config; })
          (lib.listToAttrs (lib.imap0 (i: config: lib.nameValuePair "vpn${toString i}" config) cfg.vpn.openvpn.configs));
      };

      # WireGuard configuration
      networking.wireguard = lib.mkIf (cfg.vpn.enable && cfg.vpn.wireguard.enable) {
        interfaces = cfg.vpn.wireguard.interfaces;
      };

      # Proxy configuration
      environment = lib.mkIf cfg.proxy.enable {
        variables = {
          http_proxy = cfg.proxy.httpProxy;
          https_proxy = cfg.proxy.httpsProxy;
          no_proxy = lib.concatStringsSep "," cfg.proxy.noProxy;
        };
      };

      # Network security
      security = {
        # Enable AppArmor for network services
        apparmor.enable = lib.mkDefault true;
        
        # Network security policies
        auditd.enable = lib.mkDefault true;
      };
    };
  };

in
{
  # Export networking modules
  inherit networkmanager;

  # Default networking configuration
  default = networkmanager;
}
