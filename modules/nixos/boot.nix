{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.circus.nixos.boot;
in
{
  options.circus.nixos.boot = {
    bootType = mkOption {
      type = types.enum [ "systemd-boot" "grub" ];
      default = "systemd-boot";
      description = "Use systemd-boot instead of GRUB";
    };
    timeout = mkOption {
      type = types.int;
      default = 5;
      description = "Boot timeout in seconds";
    };
    plymouth = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Plymouth boot splash";
    };
  };

  config = {
    boot = {
      # Use systemd-boot or GRUB
      loader =
        if cfg.bootType == "systemd-boot"
        then {
          systemd-boot = {
            enable = true;
            configurationLimit = 10;
            # https://mynixos.com/nixpkgs/option/boot.loader.systemd-boot.editor
            editor = false;
          };
          efi.canTouchEfiVariables = true;
          timeout = cfg.timeout;
        }
        else {
          grub = {
            enable = true;
            device = "nodev";
            efiSupport = true;
            useOSProber = true;
          };
          efi.canTouchEfiVariables = true;
          timeout = cfg.timeout;
        };

      # Plymouth boot splash
      plymouth = mkIf cfg.plymouth {
        enable = true;
        theme = "breeze";
      };

      # Kernel parameters
      kernelParams = [
        "quiet"
        "splash"
        "loglevel=3"
        "systemd.show_status=auto"
        "rd.udev.log_level=3"
      ];

      # Kernel
      kernelPackages = pkgs.linuxPackages_latest;

      tmp = {
        useTmpfs = true;
        tmpfsSize = "50%";
      };
    };
  };
}
