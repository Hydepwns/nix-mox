# Hardware auto-detection module
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.autoDetect;
  
  # Detect GPU vendor
  hasNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;
  hasAmd = builtins.elem "amdgpu" config.services.xserver.videoDrivers || 
           builtins.elem "radeon" config.services.xserver.videoDrivers;
  hasIntel = builtins.elem "intel" config.services.xserver.videoDrivers || 
             builtins.elem "modesetting" config.services.xserver.videoDrivers;
  
  # CPU detection (simplified - can't read /proc at eval time)
  hasIntelCpu = cfg.cpu.forceVendor == "intel";
  hasAmdCpu = cfg.cpu.forceVendor == "amd";
  
  # Memory detection (use reasonable defaults)
  totalMemoryGB = cfg.memory.systemMemoryGB;
  
  # Storage detection (simplified)
  hasNvme = cfg.storage.hasNvme;
  hasSsd = cfg.storage.hasSsd;
in
{
  options.hardware.autoDetect = {
    enable = mkEnableOption "automatic hardware detection and optimization";
    
    gpu = {
      autoConfig = mkEnableOption "automatic GPU configuration";
      
      forceVendor = mkOption {
        type = types.nullOr (types.enum [ "nvidia" "amd" "intel" ]);
        default = null;
        description = "Force specific GPU vendor configuration";
      };
    };
    
    cpu = {
      autoConfig = mkEnableOption "automatic CPU optimization";
      
      forceVendor = mkOption {
        type = types.nullOr (types.enum [ "intel" "amd" ]);
        default = null;
        description = "Force specific CPU vendor configuration";
      };
    };
    
    memory = {
      autoConfig = mkEnableOption "automatic memory configuration";
      
      systemMemoryGB = mkOption {
        type = types.int;
        default = 16;
        description = "System memory in GB (used for auto-configuration)";
      };
      
      zramPercent = mkOption {
        type = types.int;
        default = 50;
        description = "Percentage of RAM to use for zram";
      };
    };
    
    storage = {
      autoConfig = mkEnableOption "automatic storage optimization";
      
      hasNvme = mkOption {
        type = types.bool;
        default = true;
        description = "System has NVMe storage";
      };
      
      hasSsd = mkOption {
        type = types.bool;
        default = true;
        description = "System has SSD storage";
      };
      
      scheduler = mkOption {
        type = types.str;
        default = "none";
        description = "I/O scheduler to use";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # GPU auto-configuration
    (mkIf (cfg.gpu.autoConfig && (cfg.gpu.forceVendor == "nvidia" || hasNvidia)) {
      # NVIDIA configuration
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        forceFullCompositionPipeline = true;
      };
      
      services.xserver.videoDrivers = [ "nvidia" ];
      
      boot.blacklistedKernelModules = [ "nouveau" ];
      boot.kernelParams = [ "nvidia-drm.modeset=1" ];
      
      environment.variables = {
        __GL_THREADED_OPTIMIZATIONS = "1";
        __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
      };
      
      # NVIDIA-specific packages
      environment.systemPackages = with pkgs; [
        nvtop
        nvidia-vaapi-driver
      ];
    })
    
    (mkIf (cfg.gpu.autoConfig && (cfg.gpu.forceVendor == "amd" || hasAmd)) {
      # AMD configuration
      services.xserver.videoDrivers = [ "amdgpu" ];
      
      boot.kernelParams = [ 
        "radeon.si_support=0"
        "amdgpu.si_support=1"
        "radeon.cik_support=0"
        "amdgpu.cik_support=1"
      ];
      
      hardware.graphics = {
        extraPackages = with pkgs; [
          rocm-opencl-icd
          rocm-opencl-runtime
          amdvlk
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          amdvlk
        ];
      };
      
      environment.variables = {
        AMD_VULKAN_ICD = "RADV";
      };
      
      # AMD-specific packages
      environment.systemPackages = with pkgs; [
        radeontop
        corectrl
      ];
    })
    
    (mkIf (cfg.gpu.autoConfig && (cfg.gpu.forceVendor == "intel" || hasIntel)) {
      # Intel configuration
      services.xserver.videoDrivers = [ "modesetting" ];
      
      boot.kernelParams = [ "i915.enable_guc=2" ];
      
      hardware.graphics = {
        extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
          intel-compute-runtime
        ];
      };
      
      environment.variables = {
        VDPAU_DRIVER = "va_gl";
      };
      
      # Intel-specific packages
      environment.systemPackages = with pkgs; [
        intel-gpu-tools
      ];
    })
    
    # CPU auto-configuration
    (mkIf (cfg.cpu.autoConfig && (cfg.cpu.forceVendor == "intel" || hasIntelCpu)) {
      # Intel CPU optimizations
      hardware.cpu.intel.updateMicrocode = true;
      
      boot.kernelParams = [
        "intel_pstate=active"
        "intel_idle.max_cstate=1"
      ];
      
      boot.kernelModules = [ "kvm-intel" ];
      
      # Intel-specific performance settings
      powerManagement = {
        cpuFreqGovernor = "performance";
        powerUpCommands = ''
          # Disable Intel turbo boost throttling
          echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
        '';
      };
    })
    
    (mkIf (cfg.cpu.autoConfig && (cfg.cpu.forceVendor == "amd" || hasAmdCpu)) {
      # AMD CPU optimizations
      hardware.cpu.amd.updateMicrocode = true;
      
      boot.kernelParams = [
        "amd_pstate=active"
        "processor.max_cstate=1"
      ];
      
      boot.kernelModules = [ "kvm-amd" ];
      
      # AMD-specific performance settings
      powerManagement = {
        cpuFreqGovernor = "schedutil";  # Better for AMD Zen
      };
      
      # Enable AMD P-State driver (Zen 2+)
      boot.extraModprobeConfig = ''
        options amd_pstate shared_mem=1
      '';
    })
    
    # Memory auto-configuration
    (mkIf cfg.memory.autoConfig {
      # Configure zram based on available memory
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = cfg.memory.zramPercent;
        priority = 100;
      };
      
      # Configure vm settings based on memory
      boot.kernel.sysctl = {
        "vm.swappiness" = if totalMemoryGB >= 32 then 10 
                          else if totalMemoryGB >= 16 then 20 
                          else 30;
        "vm.vfs_cache_pressure" = if totalMemoryGB >= 32 then 50 else 100;
        "vm.dirty_background_ratio" = if totalMemoryGB >= 32 then 1 else 5;
        "vm.dirty_ratio" = if totalMemoryGB >= 32 then 2 else 10;
      };
      
      # Configure earlyoom based on memory
      services.earlyoom = {
        enable = true;
        freeMemThreshold = if totalMemoryGB >= 32 then 5 
                          else if totalMemoryGB >= 16 then 10 
                          else 15;
        freeSwapThreshold = 10;
      };
      
      # Huge pages for systems with enough memory
      boot.kernelParams = optional (totalMemoryGB >= 16) "transparent_hugepage=always";
    })
    
    # Storage auto-configuration
    (mkIf cfg.storage.autoConfig {
      # Configure I/O scheduler
      services.udev.extraRules = ''
        # NVMe devices (use none scheduler)
        ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="${cfg.storage.scheduler}"
        
        # SATA SSDs (use mq-deadline)
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="${cfg.storage.scheduler}"
        
        # HDDs (use bfq for better responsiveness)
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      '';
      
      # Enable fstrim for SSDs
      services.fstrim = {
        enable = hasNvme || hasSsd;
        interval = "weekly";
      };
      
      # Configure filesystem options based on storage type
      fileSystems = let
        ssdOptions = [ "noatime" "nodiratime" "discard=async" ];
        hddOptions = [ "noatime" ];
      in mkIf (hasNvme || hasSsd) {
        "/".options = mkDefault ssdOptions;
        "/home".options = mkDefault ssdOptions;
      };
      
      # Kernel parameters for storage
      boot.kernelParams = []
        ++ optional hasNvme "nvme_core.io_timeout=255"
        ++ optional (hasNvme || hasSsd) "scsi_mod.use_blk_mq=1";
    })
    
    # General auto-detected optimizations
    {
      # Use optimal kernel based on system
      boot.kernelPackages = 
        if totalMemoryGB >= 32 && (hasNvidia || hasAmd) 
        then pkgs.linuxPackages_zen
        else if totalMemoryGB >= 16 
        then pkgs.linuxPackages_latest
        else pkgs.linuxPackages;
      
      # Network optimizations based on memory
      boot.kernel.sysctl = mkIf (totalMemoryGB >= 16) {
        "net.core.rmem_max" = 134217728;
        "net.core.wmem_max" = 134217728;
        "net.ipv4.tcp_rmem" = "4096 87380 134217728";
        "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      };
    }
  ]);
}