{ config, pkgs, inputs, ... }:
{
  # Node Exporter for system metrics
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
      "textfile"
      "filesystem"
      "diskstats"
      "meminfo"
      "netdev"
      "cpu"
      "loadavg"
      "uname"
      "vmstat"
      "time"
      "logind"
      "interrupts"
      "ksmd"
      "processes"
      "stat"
      "tcpstat"
      "wifi"
      "bonding"
      "hwmon"
      "mdadm"
      "zfs"
      "nfs"
      "xfs"
      "supervisord"
      "systemd"
      "textfile"
      "filesystem"
      "diskstats"
      "meminfo"
      "netdev"
    ];
    port = 9100;
    listenAddress = "0.0.0.0";
  };

  # Enhanced systemd service configuration
  systemd.services.prometheus-node-exporter = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "60s";
      TimeoutStopSec = "60s";
    };
  };
}
