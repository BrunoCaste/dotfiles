lib:
with lib;
let
  utils = import ./utils.nix lib;
in rec {
  loadSources = dir:
    let
      go = dir: segs:
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
            go "${dir}/${d.name}" (segs ++ [d.name])
          ) partitionedDirs.wrong;

          baseResults = map (f:
            let name = removeSuffix ".nix" f.name;
            in {
              inherit name;
              segs = segs ++ [name];
              path = "${dir}/${f}";
          }) files ++ partitionedDirs.right;

        in
          recResults ++ baseResults;
    in
      if pathExists dir then go dir [] else [];

  loadOverlays = { inputs, dir }:
    let sources = loadSources dir;
    in lib.map (src: import src.path { inherit inputs; }) sources;

  loadPackages = { pkgs, dir }:
    let sources = loadSources dir;
    in utils.listToNestedAttrs (p: pkgs.callPackage p.path {}) sources;

  # Build a module that:
  #  - defines options.circus.<platform>.<name>.enable for each discovered module
  #  - conditionally imports the module when enabled (keeping the original module intact)
  loadModules = { platform, dir }:
    { lib, config, ... }:
    let
      sources = loadSources dir;
      options = { circus.${platform} = utils.listToNestedAttrs (opt:
        let qname = lib.concatStringsSep opt.segs;
        in {
          enable = mkEnableOption "Enable Circus ${platform} module '${qname}'";
      }) sources; };

      cfgRoot = config.circus.${platform} or {};
      enabledFor = segs: (attrByPath segs {} cfgRoot).enable or false;

      imports = map (s: mkIf (enabledFor s.segs) s.path) sources;
    in { inherit options imports; };
}
