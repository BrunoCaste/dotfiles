{ config
, lib
, pkgs
, ...
}:
with lib; {
  options.circus.nixos.bluetooth = {
    powerOnBoot = mkOption {
      type = types.bool;
      default = true;
      description = "Power on bluetooth adapter on boot";
    };
    a2dp = mkOption {
      type = types.bool;
      default = true;
      description = "Enable A2DP audio profile";
    };
  };

  config = {
    # Bluetooth support
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = config.circus.nixos.bluetooth.powerOnBoot;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = mkIf config.circus.nixos.bluetooth.a2dp true;
        };
      };
    };

    # Bluetooth manager
    services.blueman.enable = true;

    # Bluetooth packages
    environment.systemPackages = with pkgs; [
      bluez
      bluez-tools
    ];
  };
}
