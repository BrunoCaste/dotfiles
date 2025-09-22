{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.circus.home.hyprland;
in {
  options.circus.home.hyprland = {
    monitors = mkOption {
      type = types.listOf types.str;
      default = [ ",preferred,auto,auto" ];
      description = "Monitor configurations";
    };

    terminal = mkOption {
      type = types.package;
      default = pkgs.alacritty;
      description = "Default terminal emulator";
    };

    launcher = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {
            type = types.package;
            default = pkgs.wofi;
            description = "Launcher package to use";
          };
          args = mkOption {
            type = types.str;
            default = "--show drun";
            description = "Arguments passed to the launcher command";
          };
        };
      };
      default = {};
      description = "Application launcher configuration";
    };
  };

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;

      settings = {
        monitor = cfg.monitors;

        # Input configuration
        input = {
          sensitivity = 0;
          follow_mouse = 2;

          touchpad = {
            disable_while_typing = true;
            natural_scroll = true;
            tap-to-click = true;
          };
          kb_layout = "us";
        };

        # General window behavior
        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          resize_on_border = false;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
          allow_tearing = false;
        };

        # Decoration
        decoration = {
          rounding = 8;
          active_opacity = 1.0;
          inactive_opacity = 0.8;

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
            };
        };

        # Animations
        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        # Dwindle layout
        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        # Window rules
        windowrulev2 = [
          "float,class:^(pavucontrol)$"
          "float,class:^(blueman-manager)$"
          "float,class:^(nm-applet)$"
          "float,class:^(nm-connection-editor)$"
        ];

        # Key bindings
        "$mainMod" = "SUPER";

        bind = let
          terminal = getExe cfg.terminal;
          launcher = getExe cfg.launcher.package;
        in [
          # Window management
          "$mainMod, Q, killactive"
          "$mainMod SHIFT, M, exec, loginctl lock-session"
          "$mainMod, W, togglefloating"
          "$mainMod, J, togglesplit"
          "$mainMod, F, fullscreen"

          # Applications
          "$mainMod, T, exec, ${terminal}"
          "$mainMod, Space, exec, pkill -x ${launcher} || ${launcher} ${cfg.launcher.args}"

          # Focus movement
          "$mainMod, H, movefocus, l"
          "$mainMod, L, movefocus, r"
          "$mainMod, K, movefocus, u"
          "$mainMod, J, movefocus, d"

          # Window movement
          "$mainMod SHIFT, H, movewindow, l"
          "$mainMod SHIFT, L, movewindow, r"
          "$mainMod SHIFT, K, movewindow, u"
          "$mainMod SHIFT, J, movewindow, d"

          # Workspaces
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move to workspace
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          # Adjacent workspaces
          "$mainMod CTRL, H, workspace, r-1"
          "$mainMod CTRL, L, workspace, r+1"

          "$mainMod SHIFT CTRL, H, movetoworkspace, r-1"
          "$mainMod SHIFT CTRL, L, movetoworkspace, r+1"

          # Special workspace
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          # Scroll through existing workspaces
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"
        ];

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        # Media keys
        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"
        ];
      };
    };
  };
}
