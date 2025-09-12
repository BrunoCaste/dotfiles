{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.circus.nixos.hyprland;
in {
  options.circus.nixos.hyprland = {
    nvidia = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Nvidia-specific Hyprland settings";
    };
  };

  config = {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = false;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    };

    # XDG portal
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
      ];
    };

    # Session variables
    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    } // (if config.circus.nixos.hyprland.nvidia then {
      LIBVA_DRIVER_NAME = "nvidia";
      XDG_SESSION_TYPE = "wayland";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
    } else {});

    # Graphics drivers for AMD
    hardware.graphics = mkIf (!config.circus.nixos.hyprland.nvidia) {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        amdvlk
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };
  };
}
