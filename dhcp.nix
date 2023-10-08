{ config, ... }:
let
  cfg = config.pi-router;
in
{

  # TODO Setup DHCP. Maybe KEA?

  # services.dhcpd4 = {
  #   enable = true;
  # };
}

