{ config, ... }:
let
  cfg = config.pi-router;
in
{
  services.pppd = {
    enable = true;
    peers.internet-provider = {
      enable = true;
      # autostart = true;
      # see the pppd(8) man page.
      config = ''
        plugin rp-pppoe.so wan

        # pppd supports multiple ways of entering credentials,
        # this is just 1 way
        # name "xxx"
        # password "yyy"
        # We use /etc/ppp/pap-secrets
        # user         server  secret        addresses
        # "mysurename" *       "mypassword"  *

        persist
        maxfail 0
        holdoff 5

        noipdefault
        defaultroute
      '';
    };
  };

}
