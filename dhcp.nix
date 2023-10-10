{ config, ... }:
let
  cfg = config.pi-router;
in
{

  systemd.network.enable = true;

  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  networking.firewall.allowedUDPPorts = [
    # DHCP
    67
    68
  ];



  # [Match]
  # Name=wlan0

  # [Network]
  # Address=10.1.1.1/24
  # DHCPServer=true
  # IPMasquerade=ipv4

  # [DHCPServer]
  # PoolOffset=100
  # PoolSize=20
  # EmitDNS=yes
  # DNS=9.9.9.9




  systemd.network.networks.net-lan = {

    # The name of the network interface to match against. ([Match] Block)
    name = cfg.interfaces.lan.name;

    # Whether to enable DHCP on the interfaces matched.
    # Accepts "yes", "no", "ipv4", or "ipv6"
    # DHCP = "yes";

    # Each attribute in this set specifies an option in the [Network] section
    # of the unit. See systemd.network(5) for details
    networkConfig = {

      Description = "My LAN Network";
      # Takes a boolean. If set to "yes", DHCPv4 server will be started.
      # Defaults to "no". Further settings for the DHCP server may be set in
      # the [DHCPServer] section described below.
      DHCPServer = "yes";
IPMasquerade="ipv4";

      # Address=10.1.1.1/24
      # DHCPServer=true

    };

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
    dhcpServerStaticLeases = [
      # {
      #   dhcpServerStaticLeaseConfig = {
      #     Address = "192.168.1.42";
      #     MACAddress = "65:43:4a:5b:d8:5f";
      #   };
      # }
    ];

    # Each attribute in this set specifies an option in the [DHCPServer]
    # section of the unit. See systemd.network(5) for details.
    dhcpServerConfig = {
      # EmitDNS = false;
      # PoolOffset = 50;

      PoolOffset = 100;
      PoolSize = 20;
      EmitDNS = "yes";
      DNS = "9.9.9.9";

    };

    # Each attribute in this set specifies an option in the [DHCPPrefixDelegation]
    # section of the unit. See systemd.network(5) for details.
    # dhcpPrefixDelegationConfig = {
    #   Announce = true;
    #   SubnetId = "auto";
    # };

  };





}
