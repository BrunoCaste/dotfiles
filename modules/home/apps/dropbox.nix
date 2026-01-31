{ config
, lib
, pkgs
, ...
}:
with lib; {
  config = {
    home.packages = with pkgs; [
      dropbox-cli
    ];

    systemd.user.services.dropbox = {
      Unit = {
        Description = "Dropbox service";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        ExecStart = "${pkgs.dropbox}/bin/dropbox";
        Restart = "on-failure";
      };
    };
  };
}
