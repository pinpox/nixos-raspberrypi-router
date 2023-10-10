{ config, ... }:
let
  cfg = config.pi-router;
in
{

  systemd.network.enable = true;
  networking = {
    useDHCP = false;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    # nat.enable = true;
    # nat.enableIPv6 = true;
    # nat.externalInterface = "enp1s0";
    # nat.internalInterfaces = [ "enp2s0" "enp3s0" "enp4s0" ];

    firewall.interfaces =
      let
        portlist = [ 53 22 67 68 ];
      in
      {
        "${cfg.interfaces.wan.name}" = {
          allowedTCPPorts = portlist;
          allowedUDPPorts = portlist;
        };
        "${cfg.interfaces.lan.name}" = {
          allowedTCPPorts = portlist;
          allowedUDPPorts = portlist;
        };
      };
  };

  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  systemd.network.networks.net-lan = {

    # The name of the network interface to match against. ([Match] Block)
    # name = cfg.interfaces.lan.name;
    matchConfig.Name = cfg.interfaces.lan.name;

    # Whether to enable DHCP on the interfaces matched.
    # Accepts "yes", "no", "ipv4", or "ipv6"
    # DHCP = "yes";

    # Each attribute in this set specifies an option in the [Network] section
    # of the unit. See systemd.network(5) for details
    networkConfig = {

      # Description = "My LAN Network";

      # Takes a boolean. If set to "yes", DHCPv4 server will be started.
      # Defaults to "no". Further settings for the DHCP server may be set in
      # the [DHCPServer] section described below.
      DHCPServer = true;
      # IPMasquerade="ipv4";

      # Address=10.1.1.1/24
      # DHCPServer=true

    };


    # Each attribute in this set specifies an option in the [DHCPServer]
    # section of the unit. See systemd.network(5) for details.


    dhcpServerConfig = {

      # EmitDNS = false;
      # PoolOffset = 50;
      # EmitDNS = "yes";
      # ServerAddress = "192.168.101.1/24";
      DNS = [ "1.1.1.1" "1.0.0.1" ];
      PoolSize = 100;
      PoolOffset = 20;
    };
    # vlan = [ "cdwifi" "cdiot" "cdguest" ];

    # routes = [ { Gateway = "192.168.0.1"; } ];


    # A list of gateways to be added to the network section of the unit. See
    # systemd.network(5) for details.
    # gateway = [ ];
    # dns = [ "1.1.1.1" ];

    # Each attribute in this set specifies an option in the [Address] section of
    # the unit. See systemd.network(5) for details.
    # addresses = [{ Address = "192.168.0.100/24"; } ];

    # A list of addresses to be added to the network section of the unit. See
    # systemd.network(5) for details.
    address = [ "${cfg.interfaces.lan.ip}/24" ];

    # services.dhcpd4 = {
    #     enable = true;
    #     interfaces = [ "lan" "iot" ];
    #     extraConfig = ''
    #       option domain-name-servers 10.5.1.10, 1.1.1.1;
    #       option subnet-mask 255.255.255.0;

    #       subnet 10.1.1.0 netmask 255.255.255.0 {
    #         option broadcast-address 10.1.1.255;
    #         option routers 10.1.1.1;
    #         interface lan;
    #         range 10.1.1.128 10.1.1.254;
    #       }

    #       subnet 10.1.90.0 netmask 255.255.255.0 {
    #         option broadcast-address 10.1.90.255;
    #         option routers 10.1.90.1;
    #         option domain-name-servers 10.1.1.10;
    #         interface iot;
    #         range 10.1.90.128 10.1.90.254;
    #       }
    #     '';
    #   };

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





}
