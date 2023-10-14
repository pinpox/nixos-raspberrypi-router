{ pkgs, lib, config, ... }:
let
  cfg = config.pi-router;
in
{

  imports = [
    ./nixos.nix
    ./ssh.nix
    ./dns.nix
    ./hardware.nix
    ./nftables.nix
    # ./nat.nix
    # ./firewall.nix
    ./dhcp.nix
  ];

  options.pi-router = with lib;{

    dnsServers = mkOption {
      type = types.listOf types.str;
      description = "List of DNS servers";
      default = [ "1.1.1.1" "1.0.0.1" ];
      example = [ "9.9.9.9" "1.0.0.1" ];
    };

    interfaces = {
      lan = {
        ip = mkOption {
          type = types.str;
          description = "IPv4 address of the LAN interface";
          default = "192.168.101.1";
        };
        name = mkOption {
          type = types.str;
          description = "Interface used for LAN";
          default = "end0";
        };
      };

      wan = {
        # ip = mkOption {
        #   type = types.str;
        #   description = "IPv4 address of the WAN interface";
        #   default = "192.168.101.1";
        # };
        name = mkOption {
          type = types.str;
          description = "Interface used for WAN";
          default = "enp1s0";
        };
      };
    };
  };

  config = {

    # Define a user account.
    users.users.root = {
      openssh.authorizedKeys.keyFiles = [
        (pkgs.fetchurl {
          url = "https://github.com/pinpox.keys";
          sha256 = "sha256-V0ek+L0axLt8v1sdyPXHfZgkbOxqwE3Zw8vOT2aNDcE=";
        })
      ];
    };

    environment.systemPackages = with pkgs; [
      bmon # network bandwidth monitor
      conntrack-tools # view network connection states
      darkstat # network statistics web interface
      dnsutils # dig, nslookup, etc.
      ethtool # manage NIC settings (offload, NIC feeatures, ...)
      htop # to see the system load
      iftop # display bandwidth usage on a network interface
      iperf3 # speedtest between 2 devices
      ppp # for some manual debugging of pppd
      speedtest-cli # speedtest.net from the command line
      tcpdump # view network traffic
      traceroute # tracks the route taken by packets over an IP network
    ];

    # Time zone and internationalisation
    time.timeZone = "Europe/Berlin";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "de";
    };

    # allow routing between interfaces
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
    };

    # Networking
    networking = {
      hostName = "nixos-router";
      usePredictableInterfaceNames = true;

      # Use DHCP on the WAN interface (connected to existing router for now, later PPPoE)
      interfaces."${cfg.interfaces.wan.name}".useDHCP = true;

      # Don't enable on the LAN interface and instead set a static IP
      interfaces."${cfg.interfaces.lan.name}" = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "${cfg.interfaces.lan.ip}";
          prefixLength = 24;
        }];
      };
    };
  };
}
