{ config, lib, ... }:
with lib;
let
  cfg = config.pi-router;
  dns-overwrites-config = builtins.toFile "dns-overwrites.conf" (''
    # DNS overwrites
  '' + concatStringsSep "\n"
    (mapAttrsToList (n: v: "local-data: \"${n} A ${toString v}\"") cfg.unbound.A-records));
in
{

  options.pi-router.unbound = {
    A-records = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Custom DNS A records
      '';
    };
  };

  config = {
    networking.firewall.interfaces."${cfg.interfaces.lan.name}" = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };

    services.unbound = {
      enable = true;
      settings = {
        server = {
          include = [ "\"${dns-overwrites-config}\"" ];
          interface = [ "127.0.0.1" cfg.interfaces.lan.ip ];
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
  };
}
