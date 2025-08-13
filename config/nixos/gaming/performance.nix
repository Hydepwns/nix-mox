{ config, lib, pkgs, ... }:

with lib;

# Gaming performance configuration
# Handles performance optimizations, CPU governors, and system tuning

let
  cfg = config.services.gaming;
in
{
  config = mkIf (cfg.enable && cfg.performance.enable && pkgs.stdenv.hostPlatform.isx86_64) {
    # Performance optimizations
    powerManagement = {
      cpuFreqGovernor = cfg.performance.cpuGovernor;
      enable = true;
    };

    # System packages for performance tools
    environment.systemPackages = with pkgs; [
      # Performance tools
      (mkIf cfg.performance.gamemode gamemode)
      (mkIf cfg.performance.mangohud mangohud)

      # Graphics tools
      vulkan-tools

      # System monitoring
      htop
      btop
      glmark2
    ];

    # Additional performance tuning
    systemd.services.performance-tuning = {
      description = "Apply performance optimizations for gaming";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Set CPU governor to performance
        echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
        
        # Disable CPU idle states for lower latency
        echo 1 > /sys/devices/system/cpu/cpu*/power/energy_perf_bias 2>/dev/null || true
        
        # Set maximum CPU performance
        echo 0 > /sys/devices/system/cpu/cpuidle/sleep_disabled 2>/dev/null || true
        
        # I/O scheduler optimization - mq-deadline for SSDs, bfq for HDDs
        for disk in /sys/block/nvme*; do
          [ -e "$disk/queue/scheduler" ] && echo mq-deadline > "$disk/queue/scheduler" 2>/dev/null || true
        done
        
        for disk in /sys/block/sd*; do
          if [ -e "$disk/queue/rotational" ] && [ "$(cat "$disk/queue/rotational")" = "1" ]; then
            # HDD - use BFQ for better interactive performance
            echo bfq > "$disk/queue/scheduler" 2>/dev/null || true
          else
            # SSD - use mq-deadline for low latency
            echo mq-deadline > "$disk/queue/scheduler" 2>/dev/null || true
          fi
        done
        
        # Optimize NVMe queue depth for gaming
        for nvme in /sys/block/nvme*; do
          [ -e "$nvme/queue/nr_requests" ] && echo 32 > "$nvme/queue/nr_requests" 2>/dev/null || true
        done
        
        # NVIDIA-specific optimizations
        if [ -e /proc/driver/nvidia/version ]; then
          # Set NVIDIA GPU performance mode
          echo performance > /sys/bus/pci/devices/0000:01:00.0/power_state 2>/dev/null || true
          
          # Disable NVIDIA power management
          echo -1 > /sys/bus/pci/devices/0000:01:00.0/power/autosuspend_delay_ms 2>/dev/null || true
          echo on > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null || true
        fi
        
        # Intel integrated graphics optimizations
        if [ -e /sys/class/drm/card0/gt_max_freq_mhz ]; then
          # Set maximum GPU frequency
          cat /sys/class/drm/card0/gt_max_freq_mhz > /sys/class/drm/card0/gt_min_freq_mhz 2>/dev/null || true
        fi
      '';
    };
  };
} 