{ pkgs, lib, config, ... }:
let cfg = config.pi-router; in
{

  imports = [
    ./ssh.nix
    ./nixos.nix
    ./hardware.nix
  ];

  options.pi-router = {
    WAN_IF = lib.mkOption {
      type = lib.types.str;
      description = "Interface used for WAN";
    };
    LAN_IF = lib.mkOption {
      type = lib.types.str;
      description = "Interface used for LAN";
    };
    LAN_IP = lib.mkOption {
      type = lib.types.str;
      description = "IP address of the LAN interface";
    };
  };

  config = {

    pi-router = {
      WAN_IF = "eth0";
      LAN_IF = "eth1";
      LAN_IP = "192.168.101.1";
    };

    # Define a user account.
    users.users.root = {
      openssh.authorizedKeys.keyFiles = [
        (pkgs.fetchurl {
          url = "https://github.com/pinpox.keys";
          sha256 = "sha256-V0ek+L0axLt8v1sdyPXHfZgkbOxqwE3Zw8vOT2aNDcE=";
        })
      ];
    };

    # Time zone and internationalisation
    time.timeZone = "Europe/Berlin";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "de";
    };

    ### DNS server ###
    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "127.0.0.1" cfg.LAN_IP ];
          access-control = [
            "127.0.0.0/8 allow"
            "192.168.0.0/16 allow"
          ];
        };
        forward-zone = [
          {
            name = "google.*.";
            forward-addr = [
              "8.8.8.8@853#dns.google"
              "8.8.8.4@853#dns.google"
            ];
            forward-tls-upstream = "yes";
          }
          {
            name = ".";
            forward-addr = [
              "1.1.1.1@853#cloudflare-dns.com"
              "1.0.0.1@853#cloudflare-dns.com"
            ];
            forward-tls-upstream = "yes";
          }
        ];
      };
    };

    # Networking
    networking = {
      usePredictableInterfaceNames = true;
      hostName = "nixos-router";
      # interfaces.eth0 = { useDHCP = true; };
    };
  };
}
