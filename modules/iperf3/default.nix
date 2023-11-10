{ config, ... }:
let
  cfg = config.pi-router;
in
{

  networking.firewall.interfaces."${cfg.interfaces.lan.name}" = {
    allowedTCPPorts = [ 5201 ];
    allowedUDPPorts = [ 5201 ];
  };

  services.iperf3 = {
    enable = true;
    port = 5201;
    bind = cfg.interfaces.lan.ip;
  };

}
