{ config, lib, ... }:
with lib;
let
  cfg = config.pi-router;
in
{
  options.pi-router.dhcp = {
    static = mkOption {
      type = types.listOf (types.submodule {
        options = {
          ip = mkOption { type = types.str; };
          mac = mkOption { type = types.str; };
        };
      });
      default = [ ];
      example = [{
        ip = "192.168.101.2";
        mac = "02:de:ad:be:ef:01";
      }];
      description = ''
        Static DHCP leases.
      '';
    };
  };

  config = {
    systemd.network.enable = true;

    networking = {
      useDHCP = false;
      # Not used as we use our own unbound DNS. This is just a fallback.
      nameservers = [ "8.8.8.8" ];
      firewall.interfaces."${cfg.interfaces.lan.name}".allowedUDPPorts = [ 67 ];
    };

    # Useful for debugging systemd-networkds and DHCP
    # journalctl -fu  systemd-networkd.service
    # systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

    # See systemd.network(5) for details on the sections below
    systemd.network.networks.net-lan = {

      # The name of the network interface to match against. ([Match] Block)
      name = cfg.interfaces.lan.name;

      # [Network] section of the unit.
      networkConfig = {

        Description = "LAN network";

        # Takes a boolean. If set to "yes", DHCPv4 server will be started.
        # Defaults to "no". Further settings for the DHCP server may be set in
        # the [DHCPServer] section described below.
        DHCPServer = true;
        # IPMasquerade="ipv4";
        # Address=10.1.1.1/24
      };

      # [DHCPServer] section of the unit.
      dhcpServerConfig = {
        # EmitDNS = false;
        # PoolOffset = 50;
        # EmitDNS = "yes";
        # ServerAddress = "192.168.101.1/24";
        DNS = [ cfg.interfaces.lan.ip ];
        PoolSize = 100;
        PoolOffset = 20;
      };

      # A list of addresses to be added to the network section of the unit. See
      # systemd.network(5) for details.
      address = [ "${cfg.interfaces.lan.ip}/24" ];

      # Each attribute in this set specifies an option in the [DHCPv6] section of the
      # unit. See systemd.network(5) for details.
      # dhcpV6Config = {
      #   UseDNS = true;
      # };

      # Each attribute in this set specifies an option in the [DHCPv4] section of the
      # unit. See systemd.network(5) for details.
      # dhcpV4Config = {
      # UseDNS = true;
      # UseRoutes = true;
      # };

      dhcpServerStaticLeases = (map
        (lease: {
          dhcpServerStaticLeaseConfig = {
            Address = lease.ip;
            MACAddress = lease.mac;
          };
        })
        cfg.dhcp.static);

      # dhcpServerStaticLeases.*.dhcpServerStaticLeaseConfig
      # dhcpServerStaticLeases = [
      #   {
      #     dhcpServerStaticLeaseConfig = {
      #       Address = "192.168.101.2";
      #       MACAddress = "18:65:71:e5:b1:e2";
      #     };
      #   }
      # ];

      # Each attribute in this set specifies an option in the [DHCPPrefixDelegation]
      # section of the unit. See systemd.network(5) for details.
      # dhcpPrefixDelegationConfig = {
      #   Announce = true;
      #   SubnetId = "auto";
      # };

    };
  };

}

