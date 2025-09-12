{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.circus.nixos.network;
in {
  options.circus.nixos.network = {
    firewall = mkOption {
      type = types.bool;
      default = true;
      description = "Enable firewall";
    };
    openPorts = mkOption {
      type = types.listOf types.int;
      default = [];
      description = "Additional ports to open in the firewall";
    };
  };

  config = {
    networking = {
      networkmanager.enable = true;
      # NetworkManager manages DHCP
      dhcpcd.enable = false;

      firewall = mkIf cfg.firewall {
        enable = true;
        allowedTCPPorts = cfg.openPorts;
        # Common ports for development (development servers)
        allowedTCPPortRanges = [
          { from = 3000; to = 3999; }
          { from = 8000; to = 8999; }
        ];
      };

      # Enable IPv6 privacy extensions
      networkmanager.connectionConfig."ipv6.ip6-privacy" = 2;
    };

    # Network utilities
    environment.systemPackages = with pkgs; [
      iw
      wirelesstools
    ];

    # DNS
    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
      extraConfig = ''
        DNS=1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one
        DNSOverTLS=yes
      '';
    };

    users.users.bruno.extraGroups = [ "networkmanager" ];
  };
}
