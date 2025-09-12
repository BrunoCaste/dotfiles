{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.circus.nixos.sddm;
in {
  options.circus.nixos.sddm = {
    theme = mkOption {
      type = types.str;
      default = "breeze";
      description = "SDDM theme to use";
    };
    autoLogin = mkOption {
      type = types.submodule {
        options = {
	  enable = mkOption {
	    type = types.bool;
	    default = false;
	    description = "Enable auto login";
	  };
	  user = mkOption {
	    type = types.str;
	    default = bruno;
	    description = "User to auto login";
	  };
	};
      };
      default = {};
      description = "Auto login configuration";
    };
  };

  config = {
    services.displayManager.sddm = {
      enable = true;
      enableHidpi = true;
      wayland = enabled;

      theme = cfg.theme;
      autoLogin = mkIf cfg.autoLogin.enable {
        relogin = true;
	user = cfg.autoLogin.user;
      };
    };

    services.xserver = enabled;
  };
}
