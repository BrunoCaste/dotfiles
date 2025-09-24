lib:

with lib;

let
  utils = import ./utils.nix lib;
  module = import ./module.nix lib;
in rec {
  loadSources = dir:
    let
      go = dir: prefix:
        let
          entries = mapAttrsToList (name: type:
            { inherit name type; }
          ) (builtins.readDir dir);
          files = filter (e:
            e.type == "regular" && hasSuffix ".nix" e.name
          ) entries;
          dirs = filter (e: e.type == "directory") entries;

          partitionedDirs = partition (d: 
            pathExists "${dir}/${d.name}/default.nix"
          ) dirs;

          recResults = concatMap (d:
            go "${dir}/${d.name}" "${prefix}${d.name}."
          ) partitionedDirs.wrong;

          baseResults = map (f:
            let name = removeSuffix ".nix" f.name;
            in {
              name = prefix + name;
              path = "${dir}/${f.name}";
          }) (files ++ partitionedDirs.right);

        in
          recResults ++ baseResults;
    in
      if pathExists dir then go dir "" else [];

  loadOverlays = { inputs, dir }:
    let sources = loadSources dir;
    in map (src: import src.path { inherit inputs; }) sources;

  loadPackages = { pkgs, dir }:
    let sources = loadSources dir;
    in utils.listToNestedAttrs (p: pkgs.callPackage p.path {}) sources;

  loadModules = { platform, dir }:
    let sources = loadSources dir;
    in map ({ name, path }:
      module.wrapModule { inherit platform name; module = import path; }
    ) sources;
}
