{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.circus.home.hyprsleep;
in {
  options.circus.home.hyprsleep = {
    lockGrace = mkOption {
      type = types.int;
      default = 15;
      description = "Time in seconds before reguiring authentication";
    };
    lockTimeout = mkOption {
      type = types.int;
      default = 300;
      description = "Timeout in seconds before locking";
    };
    screenOffTimeout = mkOption {
      type = types.int;
      default = 600;
      description = "Timeout in seconds before turning off screen";
    };
    suspendTimeout = mkOption {
      type = types.int;
      default = 1800;
      description = "Timeout in seconds before suspending";
    };
    backgroundPath = mkOption {
      type = types.str;
      default = "screenshot";
      description = "Path to background image";
    };
  };

  config = {
    services.hypridle = let
      hyprctl = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";
      lockCmd = lib.getExe config.programs.hyprlock.package;
      lockGrace = toString cfg.lockGrace;
    in {
      enable = true;
      package = inputs.hypridle.packages.${pkgs.system}.hypridle;

      settings = {
        general = {
          after_sleep_cmd = "${hyprctl} dispatch dpms on";
          before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof ${lockCmd} || ${lockCmd} --grace ${lockGrace}";
        };

        listener = [
          {
            timeout = cfg.lockTimeout;
            on-timeout = "${lockCmd} --grace ${lockGrace}";
          }
          {
            timeout = cfg.screenOffTimeout;
            on-timeout = "${hyprctl} dispatch dpms off";
            on-resume = "${hyprctl} dispatch dpms on";
          }
          {
            timeout = cfg.suspendTimeout;
            on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];
      };
    };

    programs.hyprlock = {
      enable = true;
      package = inputs.hyprlock.packages.${pkgs.system}.hyprlock;

      settings = {
        general = {
          disable_loading_bar = true;
          grace = 30;
          hide_cursor = true;
          no_fade_in = false;
        };

        background = [
          {
            path = cfg.backgroundPath;
            blur_size = 4;
            blur_passes = 3;
            contrast = 1.3;
            brightness = 0.8;
            vibrancy = 0.21;
          }
        ];

        input-field = [
          {
            size = "200, 40";
            position = "0, 255";
            halign = "center";
            valign = "bottom";

            dots_size = 0.2;
            dots_spacing = 0.5;
            dots_center = true;

            outline_thickness = 2;
            inner_color = "rgba(140, 140, 140, 0.2)";
            outer_color = "rgba(140, 140, 140, 0.2)";
            fail_color = "rgb(202, 65, 135)";
            shadow_passes = 2;

            placeholder_text = "<i>Password</i>";
            font_color = "rgb(142, 149, 177)";
            fade_on_empty = true;
          }
        ];

        label = [
          # Date
          {
            text = ''cmd[update:3600000] date +"%d %b %Y"'';
            color = "rgba(200, 200, 200, 0.7)";
            font_size = 16;
            font_family = "JetBrains Mono Nerd Font";
            position = "0, -115";
            halign = "center";
            valign = "top";
          }
          # Time
          {
            text = ''cmd[update:1000] date +"%H:%M"'';
            color = "rgba(200, 200, 200, 0.7)";
            font_size = 72;
            font_family = "JetBrains Mono Nerd Font";
            position = "0, -140";
            halign = "center";
            valign = "top";
          }
          # User
          {
            text = "Welcome, $USER";
            color = "rgba(200, 200, 200, 0.7)";
            font_size = 20;
            font_family = "JetBrains Mono Nerd Font";
            position = "0, -200";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
