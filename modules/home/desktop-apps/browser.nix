{ config
, lib
, pkgs
, inputs
, ...
}:
with lib; {
  config = {
    home.packages = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
