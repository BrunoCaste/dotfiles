{ config
, lib
, pkgs
, inputs
, ...
}:
with lib; let
  cfg = config.circus.home.compositor.hyprland;
in
{
  options.circus.home.compositor.hyprland = {
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
          command = mkOption {
            type = types.str;
            default = "${lib.getExe pkgs.wofi}";
            description = ''
              Launcher command to use.
              Use just the binary name (e.g. "wofi", "rofi") to use the version configured
              in your home-manager config, or use `getExe pkg` for a specific package.
            '';
          };
          args = mkOption {
            type = types.str;
            default = "--show drun";
            description = "Arguments passed to the launcher command";
          };
        };
      };
      default = { };
      description = "Application launcher configuration";
    };
  };

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

      settings = {
        monitor = cfg.monitors;

        input = {
          sensitivity = 0;
          follow_mouse = 2;

          touchpad = {
            disable_while_typing = true;
            natural_scroll = true;
            tap-to-click = true;
          };
        };

        gesture = [
          "3, horizontal, workspace"
          # "3, vertical, movewindow"
          "3, pinch, special, magic"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          resize_on_border = false;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
          allow_tearing = false;
        };

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

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        windowrule = [
          "float on,  match:class ^(pavucontrol)$"
          "size 45%,  match:class ^(pavucontrol)$"
          "center on, match:class ^(pavucontrol)$"
          "float on,  match:class ^(org.pulseaudio.pavucontrol)$"
          "size 45%,  match:class ^(org.pulseaudio.pavucontrol)$"
          "center on, match:class ^(org.pulseaudio.pavucontrol)$"
          "float on,  match:class ^(nm-applet)$"
          "size 45%,  match:class ^(nm-applet)$"
          "center on, match:class ^(nm-applet)$"
          "float on,  match:class ^(nm-connection-editor)$"
          "size 45%,  match:class ^(nm-connection-editor)$"
          "center on, match:class ^(nm-connection-editor)$"

          "float on,  match:class .*blueman-manager.*"
          "size 45%,  match:class .*blueman-manager.*"
          "center on, match:class .*blueman-manager.*"
        ];

        # Key bindings
        "$mainMod" = "SUPER";

        bindr =
          let
            l = cfg.launcher;
          in
          [
            # Launcher on SUPER key alone (release)
            "SUPER, SUPER_L, exec, pkill -xf '${l.command} ${l.args}' || ${l.command} ${l.args}"
          ];

        bind =
          let
            terminal = getExe cfg.terminal;

            directions = {
              h = "l";
              left = "l";
              j = "d";
              down = "d";
              k = "u";
              up = "u";
              l = "r";
              right = "r";
            };

            mkDirectionBinds = mods: action:
              mapAttrsToList
                (key: dir: "${mods}, ${key}, ${action}, ${dir}")
                directions;

            mkWorkspaceBinds = mods: action:
              map
                (idx:
                  let
                    key =
                      if idx == 10
                      then 0
                      else idx;
                  in
                  "${mods}, ${toString key}, ${action}, ${toString idx}")
                (range 1 10);
          in
          flatten [
            # Basic window management
            "$mainMod, Q, killactive"
            "$mainMod, V, togglefloating"
            "$mainMod, F, fullscreen, 1" # Maximize (keep bars visible)
            "$mainMod SHIFT, F, fullscreen, 0" # True fullscreen (hide everything)
            "$mainMod, P, pseudo"
            "$mainMod, O, togglesplit"
            "$mainMod, C, centerwindow"
            "$mainMod SHIFT, Y, pin"

            # Terminal
            "$mainMod, T, exec, ${terminal}"

            # Submaps
            "$mainMod, X, submap, system"
            "$mainMod, R, submap, resize"
            "$mainMod, G, submap, group"
            "$mainMod, A, submap, layout"
            "$mainMod, M, submap, monitor"

            (mkDirectionBinds "$mainMod" "movefocus")
            (mkDirectionBinds "$mainMod SHIFT" "movewindow")

            # Focus workspace
            (mkWorkspaceBinds "$mainMod" "workspace")
            # Move window to workspace (and follow)
            (mkWorkspaceBinds "$mainMod SHIFT" "movetoworkspace")
            # Move window to workspace (don't follow)
            (mkWorkspaceBinds "$mainMod CTRL" "movetoworkspacesilent")

            # Adjacent workspace navigation (left/right)
            "$mainMod CTRL, H, workspace, r-1"
            "$mainMod CTRL, L, workspace, r+1"
            "$mainMod CTRL, left, workspace, r-1"
            "$mainMod CTRL, right, workspace, r+1"

            # Monitor focus (multi-monitor - up/down)
            "$mainMod CTRL, K, focusmonitor, +1"
            "$mainMod CTRL, J, focusmonitor, -1"
            "$mainMod CTRL, up, focusmonitor, +1"
            "$mainMod CTRL, down, focusmonitor, -1"

            # Move window to adjacent workspace
            "$mainMod SHIFT CTRL, H, movetoworkspace, r-1"
            "$mainMod SHIFT CTRL, L, movetoworkspace, r+1"
            "$mainMod SHIFT CTRL, left, movetoworkspace, r-1"
            "$mainMod SHIFT CTRL, right, movetoworkspace, r+1"

            # Move window to monitor (multi-monitor - up/down)
            "$mainMod SHIFT CTRL, K, movewindow, mon:+1"
            "$mainMod SHIFT CTRL, J, movewindow, mon:-1"
            "$mainMod SHIFT CTRL, up, movewindow, mon:+1"
            "$mainMod SHIFT CTRL, down, movewindow, mon:-1"

            # Move workspace to monitor
            "$mainMod ALT CTRL, K, movecurrentworkspacetomonitor, +1"
            "$mainMod ALT CTRL, J, movecurrentworkspacetomonitor, -1"
            "$mainMod ALT CTRL, up, movecurrentworkspacetomonitor, +1"
            "$mainMod ALT CTRL, down, movecurrentworkspacetomonitor, -1"

            # Scratchpad workspace
            "$mainMod, grave, togglespecialworkspace, magic"
            "$mainMod, grave, exec, hyprctl dispatch movecursor $(hyprctl cursorpos | tr -d ',')"
            "$mainMod SHIFT, grave, movetoworkspace, special:magic"

            # Scroll through existing workspaces
            "$mainMod, mouse_down, workspace, e+1"
            "$mainMod, mouse_up, workspace, e-1"

            # Screenshots
            ", Print, exec, grimblast copy area"
            "CTRL, Print, exec, grimblast copy active"
            "SHIFT, Print, exec, grimblast copy screen"
            "ALT, Print, exec, grimblast save area"
            "ALT CTRL, Print, exec, grimblast save screen"
            "ALT  SHIFT, Print, exec, grimblast save active"

            "$mainMod, TAB, changegroupactive, f"
            "$mainMod SHIFT, TAB, changegroupactive, b"
          ];

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
          "$mainMod SHIFT, mouse:272, resizewindow" # More comfortable for Laptop
        ];

        # Media keys
        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          # ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"
          ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ];

        # Repeat bindings (hold key)
        binde = [
          # Resize with ALT + hjkl/arrows (repeatable)
          "$mainMod ALT, H, resizeactive, -20 0"
          "$mainMod ALT, L, resizeactive, 20 0"
          "$mainMod ALT, K, resizeactive, 0 -20"
          "$mainMod ALT, J, resizeactive, 0 20"
          "$mainMod ALT, left, resizeactive, -20 0"
          "$mainMod ALT, right, resizeactive, 20 0"
          "$mainMod ALT, up, resizeactive, 0 -20"
          "$mainMod ALT, down, resizeactive, 0 20"
        ];
      };

      submaps = {
        resize = {
          settings = {
            bind = [
              ", H, resizeactive, -40 0"
              ", L, resizeactive, 40 0"
              ", K, resizeactive, 0 -40"
              ", J, resizeactive, 0 40"
              ", left, resizeactive, -40 0"
              ", right, resizeactive, 40 0"
              ", up, resizeactive, 0 -40"
              ", down, resizeactive, 0 40"
              #Fine resize with Shift
              "SHIFT, H, resizeactive, -10 0"
              "SHIFT, L, resizeactive, 10 0"
              "SHIFT, K, resizeactive, 0 -10"
              "SHIFT, J, resizeactive, 0 10"
              "SHIFT, left, resizeactive, -10 0"
              "SHIFT, right, resizeactive, 10 0"
              "SHIFT, up, resizeactive, 0 -10"
              "SHIFT, down, resizeactive, 0 10"

              ", escape, submap, reset"
              ", Return, submap, reset"
            ];
          };
        };

        group = {
          settings = {
            bind = [
              ", G, togglegroup"
              ", A, lockactivegroup, toggle"
              ", W, moveoutofgroup"
              ", H, moveintogroup, l"
              ", L, moveintogroup, r"
              ", K, moveintogroup, u"
              ", J, moveintogroup, d"
              ", left, moveintogroup, l"
              ", right, moveintogroup, r"
              ", up, moveintogroup, u"
              ", down, moveintogroup, d"

              ", catchall, submap, reset"
            ];
          };
        };

        layout = {
          settings = {
            bind = [
              ", S, layoutmsg, togglesplit"
              ", O, layoutmsg, orientationcycle left top"
              ", M, layoutmsg, addmaster"
              ", R, layoutmsg, removemaster"
              ", T, layoutmsg, swapwithmaster"

              ", escape, submap, reset"
              ", Return, submap, reset"
            ];
          };
        };

        monitor = {
          settings = {
            bind = [
              ", H, workspace, r-1"
              ", L, workspace, r+1"
              ", left, workspace, r-1"
              ", right, workspace, r+1"
              ", K, focusmonitor, +1"
              ", J, focusmonitor, -1"
              ", up, focusmonitor, +1"
              ", down, focusmonitor, -1"
              # Move window to workspace
              "SHIFT, H, movetoworkspace, r-1"
              "SHIFT, L, movetoworkspace, r+1"
              "SHIFT, left, movetoworkspace, r-1"
              "SHIFT, right, movetoworkspace, r+1"
              # (mkWorkspaceBinds "SHIFT" "movetoworkspace")
              "SHIFT, 1, movetoworkspace, 1"
              "SHIFT, 2, movetoworkspace, 2"
              "SHIFT, 3, movetoworkspace, 3"
              "SHIFT, 4, movetoworkspace, 4"
              "SHIFT, 5, movetoworkspace, 5"
              "SHIFT, 6, movetoworkspace, 6"
              "SHIFT, 7, movetoworkspace, 7"
              "SHIFT, 8, movetoworkspace, 8"
              "SHIFT, 9, movetoworkspace, 9"
              "SHIFT, 0, movetoworkspace, 10"
              # Move window to monitor
              "SHIFT, K, movewindow, mon:+1"
              "SHIFT, J, movewindow, mon:-1"
              "SHIFT, up, movewindow, mon:+1"
              "SHIFT, down, movewindow, mon:-1"
              # Move workspace to monitor
              ", W, movecurrentworkspacetomonitor, +1"
              "SHIFT, W, movecurrentworkspacetomonitor, -1"

              ", escape, submap, reset"
              ", Return, submap, reset"
            ];
          };
        };

        system = {
          settings = {
            bind = [
              ", L, exec, loginctl lock-session"
              ", L, submap, reset"
              ", E, exit"
              ", S, exec, systemctl suspend"
              ", S, submap, reset"
              ", R, exec, systemctl reboot"
              ", P, exec, systemctl poweroff"

              ", escape, submap, reset"
              ", Return, submap, reset"
            ];
          };
        };
      };
    };

    home.packages = with pkgs; [
      brightnessctl
      grimblast
    ];
  };
}
