{ config
, lib
, pkgs
, ...
}:
with lib; {
  config = {
    home.packages = with pkgs; [
      discord
      telegram-desktop
    ];
  };
}
