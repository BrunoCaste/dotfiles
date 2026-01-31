{ lib
, pkgs
, inputs
, ...
}:
with lib; {
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "25.05";

  networking.hostName = "joker";

  circus.nixos = {
    base = enabled;
    graphical = enabled;
    boot = enabled;
    doas = enabled;
    network = enabled;
    keyboard = enabled;

    compositor.hyprland = enabled;

    audio = enabled;
    bluetooth = enabled;

    power = {
      enable = true;
      deviceType = "laptop";
      tools.tlp = true;
      tools.thermald = true;
    };
  };

  services.timesyncd.servers = [ ];

  home-manager.users.bruno = { ... }: {
    home.stateVersion = "25.05";

    circus.home = {
      base = enabled;

      compositor.hyprland = {
        enable = true;
        monitors = [ "eDP-1,1920x1080@60,0x0,1" ];
      };
      compositor.hyprsleep = enabled;

      wayland-tools.waybar = enabled;

      desktop-apps.terminal = enabled;
      desktop-apps.browser = enabled;

      apps.social = enabled;
      apps.dropbox = enabled;
      apps.latex = enabled;

      zsh = enabled;
      cli = enabled;
      neovim = enabled;
    };
  };
}
