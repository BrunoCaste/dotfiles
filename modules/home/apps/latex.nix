{ config
, lib
, pkgs
, ...
}:
with lib; {
  config = {
    home.packages = with pkgs; [
      zathura
      (texlive.combine {
        inherit
          (texlive)
          scheme-medium
          xargs
          forloop
          pbox
          varwidth
          tools
          bigfoot
          environ
          cryptocode
          beamertheme-simpleplus
          vwcol
          wrapfig
          enumitem
          todonotes
          ;
      })
    ];
  };
}
