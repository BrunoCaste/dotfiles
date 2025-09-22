{ config, lib, pkgs, ... }:

with lib;

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji

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
}
