args @ { ... }:
let
  load = import ./load.nix args;
  module = import ./module.nix args;
  utils = import ./utils.nix args;
in
load // module // utils
