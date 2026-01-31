{ config
, lib
, pkgs
, ...
}:
with lib; {
  # The enable option is added automatically by the wrapper.

  config = {
    # Graphics drivers
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ mesa ];
    };

    # Fonts
    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
      ];

      fontconfig = {
        enable = true;
        hinting.enable = true;
        hinting.style = "slight";
        subpixel.rgba = "rgb";

        defaultFonts = {
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
          monospace = [ "FiraCode Nerd Font Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };

    # SDDM (Login Manager)
    # Moving this here as part of the graphical base for now,
    # though it could be its own module if we wanted to support GDM/LightDM.
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
