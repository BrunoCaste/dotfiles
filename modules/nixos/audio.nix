{ config, lib, pkgs, ... }:

with lib;

{
  # PipeWire audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber.enable = true;
  };

  # Additional audio packages
  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    pulsemixer
  ];

  # Disabled because we use PipeWire
  services.pulseaudio.enable = false;

  users.users.bruno.extraGroups = [ "audio" ];
}
