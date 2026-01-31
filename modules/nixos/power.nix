{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.circus.nixos.power;

  # Helper function to create CPU governor service
  mkCpuGovernorService = governor: {
    description = "Set CPU governor to ${governor}";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo ${governor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'";
    };
  };

  # Helper function to set battery charge thresholds
  mkBatteryThresholdScript = pkgs.writeShellScript "set-battery-thresholds" ''
    set -e

    # Skip if charge limiting is disabled or in calibration mode
    ${optionalString (cfg.battery.chargeThreshold == null || cfg.battery.calibrationMode) ''
      echo "Battery charge limiting disabled or in calibration mode"
      exit 0
    ''}

    CHARGE_THRESHOLD=${toString cfg.battery.chargeThreshold}
    LOW_THRESHOLD=${toString (cfg.battery.lowThreshold or 20)}

    echo "Setting battery charge thresholds: $LOW_THRESHOLD% - $CHARGE_THRESHOLD%"

    # ThinkPad (Lenovo) laptops
    if [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
      echo "Configuring ThinkPad battery thresholds"
      echo $CHARGE_THRESHOLD > /sys/class/power_supply/BAT0/charge_control_end_threshold
      echo $LOW_THRESHOLD > /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || true

      ${optionalString cfg.battery.conservationMode ''
      # Enable Lenovo conservation mode
      if [ -f /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode ]; then
        echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
      fi
    ''}

    # Dell laptops
    elif [ -d /sys/class/power_supply/BAT0 ] && command -v smbios-battery-ctl >/dev/null 2>&1; then
      echo "Configuring Dell battery thresholds"
      smbios-battery-ctl --set-custom-charge-start=$LOW_THRESHOLD
      smbios-battery-ctl --set-custom-charge-stop=$CHARGE_THRESHOLD

    # ASUS laptops
    elif [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
      echo "Configuring ASUS battery thresholds"
      echo $CHARGE_THRESHOLD > /sys/class/power_supply/BAT0/charge_control_end_threshold

    # HP laptops (newer models)
    elif [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
      echo "Configuring HP battery thresholds"
      echo $CHARGE_THRESHOLD > /sys/class/power_supply/BAT0/charge_control_end_threshold

    # Framework laptops
    elif [ -f /sys/class/power_supply/BAT1/charge_control_end_threshold ]; then
      echo "Configuring Framework battery thresholds"
      echo $CHARGE_THRESHOLD > /sys/class/power_supply/BAT1/charge_control_end_threshold

    # Generic ACPI battery control (if available)
    elif [ -f /proc/acpi/battery/BAT0/charge_control ]; then
      echo "Configuring generic ACPI battery control"
      echo $CHARGE_THRESHOLD > /proc/acpi/battery/BAT0/charge_control

    # Try via TLP if available (fallback)
    elif command -v tlp >/dev/null 2>&1; then
      echo "Using TLP for battery threshold control"
      tlp setcharge $LOW_THRESHOLD $CHARGE_THRESHOLD

    else
      echo "Warning: Battery charge control not supported on this system"
      echo "Supported systems: ThinkPad, Dell (with libsmbios), ASUS, HP, Framework"
      exit 1
    fi

    echo "Battery charge thresholds set successfully"
  '';

  # Helper function to create power profile script
  mkPowerProfileScript = profile:
    let
      settings = cfg.profiles.${profile};
    in
    pkgs.writeShellScript "power-profile-${profile}" ''
      set -e

      # CPU Governor
      ${optionalString (settings.cpuGovernor != null) ''
        echo "Setting CPU governor to ${settings.cpuGovernor}"
        echo ${settings.cpuGovernor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
      ''}

      # CPU Turbo Boost
      ${optionalString (settings.cpuTurbo != null) ''
        echo "Setting CPU turbo boost to ${
          if settings.cpuTurbo
          then "enabled"
          else "disabled"
        }"
        echo ${
          if settings.cpuTurbo
          then "0"
          else "1"
        } > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        echo ${
          if settings.cpuTurbo
          then "0"
          else "1"
        } > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
      ''}

      # GPU Power Management
      ${optionalString (settings.gpuPowerSave != null) ''
        # Intel GPU
        if [ -f /sys/class/drm/card0/gt_max_freq_mhz ]; then
          if [ "${toString settings.gpuPowerSave}" = "true" ]; then
            echo "Enabling GPU power saving"
            cat /sys/class/drm/card0/gt_min_freq_mhz > /sys/class/drm/card0/gt_max_freq_mhz 2>/dev/null || true
          else
            echo "Disabling GPU power saving"
            cat /sys/class/drm/card0/gt_RP0_freq_mhz > /sys/class/drm/card0/gt_max_freq_mhz 2>/dev/null || true
          fi
        fi

        # AMD GPU
        for card in /sys/class/drm/card*/device/power_dpm_state; do
          if [ -f "$card" ]; then
            echo ${
          if settings.gpuPowerSave
          then "battery"
          else "performance"
        } > "$card" 2>/dev/null || true
          fi
        done
      ''}

      # PCIe ASPM
      ${optionalString (settings.pciePowerSave != null) ''
        if [ -f /sys/module/pcie_aspm/parameters/policy ]; then
          echo "Setting PCIe ASPM policy"
          echo ${
          if settings.pciePowerSave
          then "powersupersave"
          else "performance"
        } > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
        fi
      ''}

      # USB Autosuspend
      ${optionalString (settings.usbAutosuspend != null) ''
        echo "Configuring USB autosuspend"
        for device in /sys/bus/usb/devices/*/power/autosuspend_delay_ms; do
          if [ -f "$device" ]; then
            echo ${toString (
          if settings.usbAutosuspend
          then 1000
          else -1
        )} > "$device" 2>/dev/null || true
          fi
        done

        for device in /sys/bus/usb/devices/*/power/control; do
          if [ -f "$device" ]; then
            echo ${
          if settings.usbAutosuspend
          then "auto"
          else "on"
        } > "$device" 2>/dev/null || true
          fi
        done
      ''}

      # SATA Link Power Management
      ${optionalString (settings.sataLinkPowerMgmt != null) ''
        echo "Configuring SATA link power management"
        for host in /sys/class/scsi_host/*/link_power_management_policy; do
          if [ -f "$host" ]; then
            echo ${
          if settings.sataLinkPowerMgmt
          then "med_power_with_dipm"
          else "max_performance"
        } > "$host" 2>/dev/null || true
          fi
        done
      ''}

      # Network Interface Power Management
      ${optionalString (settings.networkPowerSave != null) ''
        echo "Configuring network power management"
        for iface in $(${pkgs.networkmanager}/bin/nmcli -t -f DEVICE device status | grep -v lo); do
          if [ -f "/sys/class/net/$iface/device/power/control" ]; then
            echo ${
          if settings.networkPowerSave
          then "auto"
          else "on"
        } > "/sys/class/net/$iface/device/power/control" 2>/dev/null || true
          fi

          # Wake-on-LAN
          ${pkgs.ethtool}/bin/ethtool -s "$iface" wol ${
          if settings.networkPowerSave
          then "d"
          else "g"
        } 2>/dev/null || true
        done
      ''}

      echo "Applied ${profile} power profile successfully"

      # Apply battery charge thresholds
      ${optionalString (cfg.deviceType == "laptop" && cfg.battery.chargeThreshold != null) ''
        ${mkBatteryThresholdScript}
      ''}
    '';
in
{
  options.circus.nixos.power = {
    deviceType = mkOption {
      type = types.enum [ "laptop" "desktop" "server" ];
      default = "desktop";
      description = "Device type for automatic profile selection";
    };

    autoSwitchProfiles = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically switch between power profiles based on AC adapter status (laptops only)";
    };

    defaultProfile = mkOption {
      type = types.enum [ "performance" "balanced" "power-save" ];
      default =
        if cfg.deviceType == "laptop"
        then "balanced"
        else "performance";
      description = "Default power profile to use";
    };

    acpiListenEvents = mkOption {
      type = types.listOf types.str;
      default = [ "ac_adapter" "battery" ];
      description = "ACPI events to listen for automatic profile switching";
    };

    thermalThresholds = {
      warning = mkOption {
        type = types.int;
        default = 80;
        description = "Temperature threshold (°C) to switch to power-save profile";
      };

      critical = mkOption {
        type = types.int;
        default = 90;
        description = "Temperature threshold (°C) for emergency throttling";
      };
    };

    profiles = {
      performance = {
        cpuGovernor = mkOption {
          type = types.nullOr (types.enum [ "performance" "powersave" "userspace" "ondemand" "conservative" "schedutil" ]);
          default = "performance";
          description = "CPU frequency governor for performance profile";
        };

        cpuTurbo = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable CPU turbo boost";
        };

        gpuPowerSave = mkOption {
          type = types.nullOr types.bool;
          default = false;
          description = "Enable GPU power saving features";
        };

        pciePowerSave = mkOption {
          type = types.nullOr types.bool;
          default = false;
          description = "Enable PCIe Active State Power Management";
        };

        usbAutosuspend = mkOption {
          type = types.nullOr types.bool;
          default = false;
          description = "Enable USB autosuspend";
        };

        sataLinkPowerMgmt = mkOption {
          type = types.nullOr types.bool;
          default = false;
          description = "Enable SATA link power management";
        };

        networkPowerSave = mkOption {
          type = types.nullOr types.bool;
          default = false;
          description = "Enable network interface power saving";
        };
      };

      balanced = {
        cpuGovernor = mkOption {
          type = types.nullOr (types.enum [ "performance" "powersave" "userspace" "ondemand" "conservative" "schedutil" ]);
          default = "schedutil";
          description = "CPU frequency governor for balanced profile";
        };

        cpuTurbo = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable CPU turbo boost";
        };

        gpuPowerSave = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable GPU power saving features";
        };

        pciePowerSave = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable PCIe Active State Power Management";
        };

        usbAutosuspend = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable USB autosuspend";
        };

        sataLinkPowerMgmt = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable SATA link power management";
        };

        networkPowerSave = mkOption {
          type = types.nullOr types.bool;
          default = false;
          description = "Enable network interface power saving";
        };
      };

      power-save = {
        cpuGovernor = mkOption {
          type = types.nullOr (types.enum [ "performance" "powersave" "userspace" "ondemand" "conservative" "schedutil" ]);
          default = "powersave";
          description = "CPU frequency governor for power-save profile";
        };

        cpuTurbo = mkOption {
          type = types.nullOr types.bool;
          default = false;
          description = "Enable CPU turbo boost";
        };

        gpuPowerSave = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable GPU power saving features";
        };

        pciePowerSave = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable PCIe Active State Power Management";
        };

        usbAutosuspend = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable USB autosuspend";
        };

        sataLinkPowerMgmt = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable SATA link power management";
        };

        networkPowerSave = mkOption {
          type = types.nullOr types.bool;
          default = true;
          description = "Enable network interface power saving";
        };
      };
    };

    customCommands = {
      onProfileSwitch = mkOption {
        type = types.lines;
        default = "";
        description = "Custom commands to run when switching power profiles";
      };

      onAcConnect = mkOption {
        type = types.lines;
        default = "";
        description = "Custom commands to run when AC adapter is connected";
      };

      onAcDisconnect = mkOption {
        type = types.lines;
        default = "";
        description = "Custom commands to run when AC adapter is disconnected";
      };
    };

    battery = {
      chargeThreshold = mkOption {
        type = types.nullOr (types.ints.between 1 100);
        default =
          if cfg.deviceType == "laptop"
          then 80
          else null;
        description = "Maximum battery charge percentage (1-100). Set to null to disable charge limiting.";
      };

      lowThreshold = mkOption {
        type = types.nullOr (types.ints.between 1 99);
        default =
          if cfg.deviceType == "laptop"
          then 20
          else null;
        description = "Minimum battery charge percentage before starting charge (1-99). Must be lower than chargeThreshold.";
      };

      conservationMode = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Lenovo conservation mode (charges to ~60% for prolonged AC use)";
      };

      calibrationMode = mkOption {
        type = types.bool;
        default = false;
        description = "Temporarily disable charge limiting for battery calibration";
      };
    };

    tools = {
      powerTop = mkEnableOption "PowerTOP power management tool";
      tlp = mkEnableOption "TLP power management (conflicts with this module's settings)";
      thermald = mkEnableOption "Intel thermald thermal management daemon";
    };
  };

  config = mkIf cfg.enable {
    # Ensure required kernel modules are loaded
    boot.kernelModules = [ "msr" "cpufreq_stats" ];

    # Enable CPU frequency scaling
    powerManagement.cpuFreqGovernor = mkDefault cfg.profiles.${cfg.defaultProfile}.cpuGovernor;

    # Install power management tools
    environment.systemPackages = with pkgs;
      [
        acpi
        lm_sensors
        ethtool
        pciutils
        usbutils
        powertop
      ]
      ++ optional cfg.tools.powerTop powertop
      ++ optional (cfg.deviceType == "laptop") acpi
      ++ optional (cfg.battery.chargeThreshold != null) (pkgs.writeShellScriptBin "battery-threshold" ''
        case "$1" in
          status)
            echo "Battery charge threshold settings:"
            if [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
              echo "  Charge stop: $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold)%"
            fi
            if [ -f /sys/class/power_supply/BAT0/charge_control_start_threshold ]; then
              echo "  Charge start: $(cat /sys/class/power_supply/BAT0/charge_control_start_threshold)%"
            fi
            if [ -f /sys/class/power_supply/BAT0/status ]; then
              echo "  Current status: $(cat /sys/class/power_supply/BAT0/status)"
            fi
            if [ -f /sys/class/power_supply/BAT0/capacity ]; then
              echo "  Current charge: $(cat /sys/class/power_supply/BAT0/capacity)%"
            fi
            ;;
          calibrate-start)
            echo "Starting battery calibration..."
            systemctl stop battery-threshold-manager
            echo "Battery charge limiting temporarily disabled"
            echo "Fully charge and discharge your battery, then run 'battery-threshold calibrate-end'"
            ;;
          calibrate-end)
            echo "Ending battery calibration..."
            systemctl start battery-threshold-manager
            echo "Battery charge limiting re-enabled"
            ;;
          reset)
            echo "Resetting battery thresholds..."
            ${mkBatteryThresholdScript}
            ;;
          *)
            echo "Usage: $0 {status|calibrate-start|calibrate-end|reset}"
            exit 1
            ;;
        esac
      '')
      ++ [
        (pkgs.writeShellScriptBin "power-profile" ''
          case "$1" in
            performance)
              echo "Switching to performance profile..."
              ${mkPowerProfileScript "performance"}
              ${cfg.customCommands.onProfileSwitch}
              ;;
            balanced)
              echo "Switching to balanced profile..."
              ${mkPowerProfileScript "balanced"}
              ${cfg.customCommands.onProfileSwitch}
              ;;
            power-save)
              echo "Switching to power-save profile..."
              ${mkPowerProfileScript "power-save"}
              ${cfg.customCommands.onProfileSwitch}
              ;;
            status)
              echo "Current CPU governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
              if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
                turbo_status=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
                echo "Turbo boost: $([ "$turbo_status" = "0" ] && echo "enabled" || echo "disabled")"
              fi
              ;;
            *)
              echo "Usage: $0 {performance|balanced|power-save|status}"
              exit 1
              ;;
          esac
        '')
      ];

    # TLP integration (if enabled)
    services.tlp.enable = cfg.tools.tlp;

    # Thermald (Intel thermal management)
    services.thermald.enable = cfg.tools.thermald;

    # Systemd services for power profiles
    systemd.services = {
      "power-profile-default" = {
        description = "Apply default power profile";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = mkPowerProfileScript cfg.defaultProfile;
        };
      };

      # Battery threshold manager
      "battery-threshold-manager" = mkIf (cfg.deviceType == "laptop" && cfg.battery.chargeThreshold != null && !cfg.battery.calibrationMode) {
        description = "Manage battery charge thresholds";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = mkBatteryThresholdScript;
          ExecReload = mkBatteryThresholdScript;
        };
      };

      # Battery monitoring service
      "battery-monitor" = mkIf (cfg.deviceType == "laptop" && cfg.battery.chargeThreshold != null) {
        description = "Monitor battery status and enforce thresholds";
        wantedBy = [ "multi-user.target" ];
        after = [ "battery-threshold-manager.service" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "30s";
          ExecStart = pkgs.writeShellScript "battery-monitor" ''
            while true; do
              if [ -f /sys/class/power_supply/BAT0/capacity ]; then
                capacity=$(cat /sys/class/power_supply/BAT0/capacity)
                status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")

                # Log battery status every hour
                current_time=$(date +%s)
                last_log_file="/tmp/battery_last_log"

                if [ ! -f "$last_log_file" ] || [ $((current_time - $(cat "$last_log_file" 2>/dev/null || echo 0))) -gt 3600 ]; then
                  echo "$(date): Battery at $capacity%, status: $status"
                  echo "$current_time" > "$last_log_file"
                fi

                # Check if thresholds are being respected
                ${optionalString (!cfg.battery.calibrationMode) ''
              if [ "$status" = "Charging" ] && [ "$capacity" -gt ${toString cfg.battery.chargeThreshold} ]; then
                echo "Warning: Battery charging beyond threshold ($capacity% > ${toString cfg.battery.chargeThreshold}%)"
                # Try to re-apply thresholds
                ${mkBatteryThresholdScript} || true
              fi
            ''}
              fi

              sleep 60
            done
          '';
        };
      };

      # ACPI event handler for automatic profile switching (laptops)
      "power-profile-acpi-handler" = mkIf (cfg.deviceType == "laptop" && cfg.autoSwitchProfiles) {
        description = "Handle ACPI events for power profile switching";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = pkgs.writeShellScript "acpi-handler" ''
            ${pkgs.acpid}/bin/acpi_listen | while read event; do
              case "$event" in
                *"ac_adapter"*"00000001"*|*"ACPI0003:00"*"00000001"*)
                  echo "AC adapter connected"
                  ${mkPowerProfileScript "performance"}
                  ${cfg.customCommands.onAcConnect}
                  ;;
                *"ac_adapter"*"00000000"*|*"ACPI0003:00"*"00000000"*)
                  echo "AC adapter disconnected"
                  ${mkPowerProfileScript "power-save"}
                  ${cfg.customCommands.onAcDisconnect}
                  ;;
              esac
            done
          '';
        };
      };

      # Thermal monitoring service
      "thermal-monitor" = {
        description = "Monitor system temperature and adjust power profiles";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = pkgs.writeShellScript "thermal-monitor" ''
            while true; do
              if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
                temp=$(cat /sys/class/thermal/thermal_zone0/temp)
                temp_c=$((temp / 1000))

                if [ "$temp_c" -gt ${toString cfg.thermalThresholds.critical} ]; then
                  echo "Critical temperature ($temp_c°C), emergency throttling"
                  ${mkPowerProfileScript "power-save"}
                elif [ "$temp_c" -gt ${toString cfg.thermalThresholds.warning} ]; then
                  echo "High temperature ($temp_c°C), switching to power-save"
                  ${mkPowerProfileScript "power-save"}
                fi
              fi
              sleep 30
            done
          '';
        };
      };
    };

    # Enable ACPID for laptop power management
    services.acpid.enable = mkIf (cfg.deviceType == "laptop") true;

    # Kernel parameters based on device type
    boot.kernelParams =
      optionals (cfg.deviceType == "laptop") [
        "pcie_aspm=force"
        "i915.enable_rc6=1"
        "i915.enable_fbc=1"
        "i915.lvds_downclock=1"
      ]
      ++ optionals (cfg.deviceType != "laptop") [
        "processor.max_cstate=1"
        "intel_idle.max_cstate=0"
      ];

    # Assertions for battery configuration
    assertions = [
      {
        assertion = cfg.battery.chargeThreshold == null || cfg.battery.lowThreshold == null || cfg.battery.lowThreshold < cfg.battery.chargeThreshold;
        message = "battery.lowThreshold must be lower than battery.chargeThreshold";
      }
      {
        assertion = cfg.deviceType == "laptop" || cfg.battery.chargeThreshold == null;
        message = "Battery charge limiting is only supported on laptops";
      }
    ];

    # Udev rules for power management
    services.udev.extraRules = ''
      # Enable runtime PM for PCI devices
      ${optionalString (cfg.profiles.${cfg.defaultProfile}.pciePowerSave == true) ''
        SUBSYSTEM=="pci", ATTR{power/control}="auto"
      ''}

      # Enable runtime PM for USB devices
      ${optionalString (cfg.profiles.${cfg.defaultProfile}.usbAutosuspend == true) ''
        SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
      ''}
    '';
  };
}
