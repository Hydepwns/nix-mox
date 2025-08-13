{ config, lib, pkgs, ... }:

with lib;

# Gaming hardware configuration
# Handles GPU, graphics, and hardware-specific settings

let
  cfg = config.services.gaming;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isx86_64) {
    # Hardware configuration
    hardware = {
      # Graphics support (updated from opengl)
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = mkMerge [
          (with pkgs; [
            vaapiVdpau
            libvdpau-va-gl
          ])
          (mkIf (cfg.gpu.type == "amd" || cfg.gpu.amd.enable) (with pkgs; [
            amdvlk
            rocm-opencl-icd
            rocm-opencl-runtime
          ]))
          (mkIf (cfg.gpu.type == "intel" || cfg.gpu.intel.enable) (with pkgs; [
            intel-media-driver
            vaapiIntel
            vaapiVdpau
          ]))
        ];
        # Only include 32-bit packages on x86_64 systems
        extraPackages32 = if pkgs.stdenv.hostPlatform.isx86_64 then with pkgs.pkgsi686Linux; [
          vaapiVdpau
          libvdpau-va-gl
        ] else [];
      };
    };

    # NVIDIA configuration - simplified conditional
    hardware.nvidia = mkIf (cfg.gpu.type == "nvidia" || cfg.gpu.nvidia.enable) {
      modesetting.enable = cfg.gpu.nvidia.modesetting.enable;
      powerManagement.enable = cfg.gpu.nvidia.powerManagement.enable;
      open = cfg.gpu.nvidia.open;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      # Note: Prime configuration removed due to option conflicts
      # For hybrid setups, configure manually in hardware config
    };

    # X server video drivers for NVIDIA
    services.xserver.videoDrivers = mkIf (cfg.gpu.type == "nvidia" || cfg.gpu.nvidia.enable) [ "nvidia" ];

    # Kernel modules for gaming - include both Intel and AMD virtualization support
    boot.kernelModules = [
      "kvm-intel" # For Intel virtualization
      "kvm-amd"   # For AMD virtualization
    ];

    # Boot configuration for gaming
    boot = {
      # Use latest kernel for best gaming performance
      kernelPackages = mkDefault pkgs.linuxPackages_latest;

      # Kernel parameters for gaming
      kernelParams = [
        "intel_iommu=on" # For GPU passthrough
        "iommu=pt" # For GPU passthrough
        "nvidia-drm.modeset=1" # For NVIDIA modesetting
        # Memory management optimizations
        "transparent_hugepage=madvise" # Better memory allocation
        "vm.swappiness=1" # Minimize swapping for gaming
        "vm.vfs_cache_pressure=50" # Balance cache pressure
        "vm.dirty_ratio=3" # Reduce dirty page ratio for better responsiveness
        "vm.dirty_background_ratio=1" # Background writeback threshold
        # Gaming-specific kernel parameters
        "preempt=full" # Full preemption for lower latency
        "rcu_nocb_poll" # RCU callback polling for smoother gameplay
        "nohz_full=1-7" # Disable timer ticks on cores 1-7 for gaming
        "isolcpus=1-7" # Isolate cores for gaming processes
        "processor.max_cstate=1" # Limit CPU C-states for consistent performance
        "intel_idle.max_cstate=1" # Intel-specific idle state limitation
        "idle=poll" # Polling idle for minimal latency
        # Graphics optimizations
        "nvidia.NVreg_UsePageAttributeTable=1" # NVIDIA PAT optimization
        "nvidia.NVreg_InitializeSystemMemoryAllocations=0" # Faster allocation
        "nvidia.NVreg_DynamicPowerManagement=0x00" # Disable power management
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Preserve VRAM
      ];
    };
  };
} 