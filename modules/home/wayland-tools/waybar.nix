{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.circus.home.wayland-tools.waybar;
in
{
  options.circus.home.wayland-tools.waybar = {
    position = mkOption {
      type = types.enum [ "top" "bottom" ];
      default = "top";
      description = "Bar position";
    };
  };

  config = {
    assertions = [
      {
        # Ensure Hyprland is enabled if Waybar is enabled
        assertion = config.circus.home.compositor.hyprland.enable;
        message = "Waybar requires Hyprland to be enabled.";
      }
    ];

    programs.waybar = {
      enable = true;
      systemd.enable = true;

      settings = {
        mainBar = {
          layer = "top";
          position = cfg.position;
          height = 30;
          spacing = 4;

          modules-left = [ "hyprland/workspaces" "hyprland/window" ];
          modules-center = [ "idle_inhibitor" "clock" ];
          modules-right = [ "backlight" "network" "bluetooth" "pulseaudio" "battery" "tray" ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            active-only = false;
            persistent-workspaces = {
              "*" = 4;
            };
          };

          "hyprland/window" = {
            format = "{}";
            separate-outputs = true;
            max-length = 50;
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "󰥔";
              deactivated = "";
            };
          };

          tray = {
            icon-size = 10;
            spacing = 5;
          };

          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%d/%m}";
            tooltip-format = "<tt><big>{calendar}</big></tt>";
          };

          backlight = {
            format = "{icon} {percent}%";
            format-icons = [ "" "" "" "" "" "" "" "" "" ];
            on-scroll-up = "brightnessctl set 1%+";
            on-scroll-down = "brightnessctl set 1%-";
          };

          network = {
            format-wifi = "󰤨 {essid}";
            format-alt = "󰤨 {signalStrength}%";
            format-ethernet = "󱘖 Wired";
            format-linked = "󱘖 {ifname} (No IP) ";
            format-disconnected = " Disconnected";
            tooltip-format = " {ifname} via {gwaddr} ";
          };

          battery = {
            states = {
              good = 95;
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}% ";
            format-plugged = " {capacity}% ";
            format-alt = "{time} {icon}";
            format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          };

          bluetooth = {
            format = "";
            format-connected = " {num_connections}";
            tooltip-format = "{controller_alias}\n\n{num_connections} connected";
            tooltip-format-connected = "{device_enumerate}";
            tooltip-format-enumerate-connected = " {device_alias}";
            tooltip-format-enumerate-connected-battery = " {device_alias}\t{device_battery_percentage}%";
            on-click = "blueman-manager";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "󰖁";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [ "" "" "" ];
            };
            on-click = "pavucontrol";
          };
        };
      };

      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: "JetBrains Mono Nerd Font", "Font Awesome 6 Free";
          font-weight: bold;
          font-size: 10px;
          min-height: 10px;
        }

        window#waybar {
          background-color: rgba(0, 0, 0, 0);
        }

        #workspaces button {
          padding: 0 5px;
          background-color: transparent;
          color: #ffffff;
          border-bottom: 3px solid transparent;
          min-width: 30px;
        }

        #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
        }

        #workspaces button.focused {
          background-color: #64727d;
          border-bottom: 3px solid #ffffff;
        }

        #workspaces button.urgent {
          background-color: #eb4d4b;
        }

        #mode {
          background-color: #64727d;
          border-bottom: 3px solid #ffffff;
        }

        #clock,
        #battery,
        #cpu,
        #memory,
        #disk,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #wireplumber,
        #custom-media,
        #tray,
        #mode,
        #idle_inhibitor,
        #scratchpad,
        #bluetooth,
        #mpd {
          padding: 0 10px;
          color: #ffffff;
        }

        #window,
        #workspaces {
          margin: 0 4px;
        }

        .modules-left > widget:first-child > #workspaces {
          margin-left: 0;
        }

        .modules-right > widget:last-child > #workspaces {
          margin-right: 0;
        }

        #clock {
          background-color: #64727d;
        }

        #battery {
          background-color: #ffffff;
          color: #000000;
        }

        #battery.charging, #battery.plugged {
          color: #ffffff;
          background-color: #26a65b;
        }

        @keyframes blink {
          to {
            background-color: #ffffff;
            color: #000000;
          }
        }

        #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        #network {
          background-color: #2980b9;
        }

        #network.disconnected {
          background-color: #f53c3c;
        }

        #pulseaudio {
          background-color: #f1c40f;
          color: #000000;
        }

        #pulseaudio.muted {
          background-color: #90b1b1;
          color: #2a5c45;
        }

        #bluetooth {
          background-color: #2e3440;
        }

        #bluetooth.connected {
          background-color: #5e81ac;
        }

        #tray {
          background-color: #2980b9;
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: #eb4d4b;
        }

        #idle_inhibitor {
          background-color: #2d3748;
        }

        #idle_inhibitor.activated {
          background-color: #ecf0f1;
          color: #2d3748;
        }
      '';
    };
  };
}
