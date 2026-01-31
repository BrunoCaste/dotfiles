{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.circus.home.desktop-apps.terminal;
in
{
  options.circus.home.desktop-apps.terminal = {
    font = mkOption {
      type = types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            default = "FiraCode Nerd Font Mono";
            description = "Font family name";
          };
          size = mkOption {
            type = types.int;
            default = 12;
            description = "Font size";
          };
        };
      };
      default = { };
      description = "Font configuration";
    };
  };

  config = {
    programs.alacritty = {
      enable = true;

      settings = {
        window = {
          padding = {
            x = 2;
            y = 2;
          };
          dynamic_padding = true;

          decorations = "None";
          opacity = 0.9;
          blur = true;

          dynamic_title = true;
        };

        scrolling = {
          history = 10000;
          multiplier = 3;
        };

        font = {
          size = cfg.font.size;

          normal.family = cfg.font.name;

          normal.style = "Regular";
          bold.style = "Bold";
          italic.style = "Italic";
          bold_italic.style = "Bold Italic";
        };

        selection.semantic_escape_chars = ",│`|:\"' ()[]{}<>\t";

        mouse.hide_when_typing = true;

        cursor = {
          blink_interval = 500;
          unfocused_hollow = true;

          style = {
            shape = "Block";
            blinking = "On";
          };
        };

        colors = {
          transparent_background_colors = true;
          draw_bold_text_with_bright_colors = true;

          primary = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
            dim_foreground = "#7f849c";
            bright_foreground = "#cdd6f4";
          };
          cursor = {
            text = "#1e1e2e";
            cursor = "#f5e0dc";
          };
          vi_mode_cursor = {
            text = "#1e1e2e";
            cursor = "#b4befe";
          };
          search = {
            matches = {
              foreground = "#1e1e2e";
              background = "#a6adc8";
            };
            focused_match = {
              foreground = "#1e1e2e";
              background = "#a6e3a1";
            };
          };
          hints = {
            start = {
              foreground = "#1e1e2e";
              background = "#f9e2af";
            };
            end = {
              foreground = "#1e1e2e";
              background = "#a6adc8";
            };
          };
          selection = {
            text = "#1e1e2e";
            background = "#f5e0dc";
          };
          normal = {
            black = "#45475a";
            red = "#f38ba8";
            green = "#a6e3a1";
            yellow = "#f9e2af";
            blue = "#89b4fa";
            magenta = "#f5c2e7";
            cyan = "#94e2d5";
            white = "#bac2de";
          };
          bright = {
            black = "#585b70";
            red = "#f38ba8";
            green = "#a6e3a1";
            yellow = "#f9e2af";
            blue = "#89b4fa";
            magenta = "#f5c2e7";
            cyan = "#94e2d5";
            white = "#a6adc8";
          };
          dim = {
            black = "#45475a";
            red = "#f38ba8";
            green = "#a6e3a1";
            yellow = "#f9e2af";
            blue = "#89b4fa";
            magenta = "#f5c2e7";
            cyan = "#94e2d5";
            white = "#bac2de";
          };
        };

        keyboard.bindings = [
          # Copy/Paste
          {
            key = "V";
            mods = "Control|Shift";
            action = "Paste";
          }
          {
            key = "C";
            mods = "Control|Shift";
            action = "Copy";
          }

          # Font size
          {
            key = "Plus";
            mods = "Control";
            action = "IncreaseFontSize";
          }
          {
            key = "Minus";
            mods = "Control";
            action = "DecreaseFontSize";
          }
          {
            key = "Key0";
            mods = "Control";
            action = "ResetFontSize";
          }
        ];
      };
    };
  };
}
