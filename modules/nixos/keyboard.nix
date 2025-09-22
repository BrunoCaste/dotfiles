{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.circus.nixos.keyboard;
in {
  options.circus.nixos.keyboard = {
    swapCapsEscape = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to swap caps lock and escape keys";
    };
    layout = mkOption {
      type = types.str;
      default = "us";
      description = "Keyboard layout";
    };
    variant = mkOption {
      type = types.str;
      default = "altgr-intl";
      description = "Keyboard layout variant";
    };
  };

  config = {
    # Console keymap
    console.useXkbConfig = true;

    # X11 keyboard configuration
    services.xserver.xkb = {
      layout = cfg.layout;
      variant = cfg.variant;
      options = mkIf cfg.swapCapsEscape "caps:swapescape";
    };

    home-manager.users.bruno.wayland.windowManager.hyprland.settings.input = {
      kb_layout = cfg.layout;
      kb_variant = cfg.variant;
      kb_options = mkIf cfg.swapCapsEscape "caps:swapescape";
    };

    # Also set for TTY
    systemd.services.swap-caps-escape = mkIf cfg.swapCapsEscape {
      description = "Swap Caps Lock and Escape keys";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.kbd}/bin/loadkeys ${pkgs.writeText "caps-escape.map" ''
          keymaps 0-127
          keycode 1 = Caps_Lock
          keycode 58 = Escape
        ''}";
      };
    };

    # Environment variables for Wayland
    environment.sessionVariables = mkIf cfg.swapCapsEscape {
      XKB_DEFAULT_OPTIONS = "caps:swapescape";
    };
  };
}
