{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.circus.nixos.doas;
in
{
  options.circus.nixos.doas = {
    wheelNoPass = mkOption {
      type = types.bool;
      default = false;
      description = "Allow wheel group to use doas without password";
    };
    keepEnv = mkOption {
      type = types.listOf types.str;
      default = [ "PATH" "EDITOR" ];
      description = "Environment variables to keep when using doas";
    };
  };

  config = {
    security.sudo.enable = false;
    security.doas.enable = true;

    security.doas.extraRules = [
      {
        groups = [ "wheel" ];
        keepEnv = true;
        persist = true;
        noPass = cfg.wheelNoPass;
        setEnv = cfg.keepEnv;
      }
      {
        users = [ "bruno" ];
        keepEnv = true;
        persist = true;
        noPass = cfg.wheelNoPass;
        setEnv = cfg.keepEnv;
      }
    ];

    # Completion
    environment.systemPackages = with pkgs; [
      doas
    ];
  };
}
