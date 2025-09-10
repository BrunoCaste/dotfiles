lib:

with lib;

{
  enabled = { enable = true; };
  disabled = { enable = false; };

  wrapModule = { platform, name, module }:
  let
    modArgs = functionArgs module;
    newMod = args@{ config, ... }:
    let
      path = splitString "." name;
      cfg = getAttrFromPath path config.circus.${platform};
      baseModule = module args;
      wrapperOpts = {
        circus.${platform} = setAttrByPath path {
          enable = mkEnableOption "Enable ${name} Circus module (${platform})";
        };
      };
    in
    {
      options = recursiveUpdate wrapperOpts (baseModule.options or {});
      config = mkIf cfg.enable (baseModule.config or baseModule);
    };
  in
    setFunctionArgs newMod (functionArgs newMod // modArgs);
}
