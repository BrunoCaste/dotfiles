{ config
, lib
, pkgs
, inputs
, ...
}:
with lib; let
  cfg = config.circus.nixos.compositor.hyprland;
in
{
  options.circus.nixos.compositor.hyprland = {
    nvidia = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Nvidia-specific Hyprland settings";
    };
  };

  config = {
    assertions = [
      {
        assertion = config.circus.nixos.graphical.enable;
        message = "Hyprland requires circus.nixos.graphical to be enabled.";
      }
    ];

    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    # XDG portal
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    # Session variables
    environment.sessionVariables =
      {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
      }
      // (
        if cfg.nvidia
        then {
          LIBVA_DRIVER_NAME = "nvidia";
          XDG_SESSION_TYPE = "wayland";
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          WLR_NO_HARDWARE_CURSORS = "1";
        }
        else { }
      );
  };
}
