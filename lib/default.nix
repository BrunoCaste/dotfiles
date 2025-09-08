lib:
let
  load = import ./load.nix lib;
  options = import ./options.nix lib;
  utils = import ./utils.nix lib;
in load // options // utils
