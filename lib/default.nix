lib:
let
  load = import ./load.nix lib;
  module = import ./module.nix lib;
  utils = import ./utils.nix lib;
in load // module // utils
