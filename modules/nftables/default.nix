{ config, lib, ... }:
with lib;
let
  cfg = config.pi-router.interfaces;
in
{
  options.pi-router.nftables = {
    traffic-shaping = mkEnableOption "enable traffic shaping";
  };

  config = {

    # Check out https://wiki.nftables.org/ for better documentation.
    # Table for both IPv4 and IPv6.

    # Matching by interface (https://wiki.nftables.org/wiki-nftables/index.php/Matching_packet_metainformation)
    # iifname -> input interface name
    # oifname -> output interface name

    # ip (https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes#Ip)
    # ip saddr -> Source address
    # ip daddr -> Destination address
    # ip protocol { icmp, esp, ah, comp, udp, udplite, tcp, dccp, sctp } -> Upper layer protocol

    # tcp (https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes#Tcp)
    # tcp dport -> Destination port

    # udp (https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes#Udp)
    # udp dport -> Destination port

    # ct (https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes#Ct)
    # ct state { new, established, related, untracked } -> State of the connection

    networking = {

      firewall.enable = true;
      nftables.enable = true;

      nat = {
        enable = true;
        externalInterface = cfg.wan.name;
        internalInterfaces = [ cfg.lan.name ];
      };

      firewall.extraInputRules = ''

      # TODO: add for IPv6
      # ICMP:
      # routers may also want: mld-listener-query, nd-router-solicit
      # ip6 nexthdr icmpv6 icmpv6 type {
      #   destination-unreachable,
      #   packet-too-big,
      #   time-exceeded,
      #   parameter-problem,
      #   nd-router-advert,
      #   nd-neighbor-solicit,
      #   nd-neighbor-advert
      # } accept

      ip protocol icmp icmp type {
        destination-unreachable,
        router-advertisement,
        time-exceeded,
        parameter-problem
      } accept

      # count and drop any other traffic
      counter drop
    '';

      firewall.filterForward = true;

      firewall.extraForwardRules = ''
        # type filter hook forward priority 0;
        # allow LAN to WAN
        iifname "${cfg.lan.name}" oifname "${cfg.wan.name}" accept
        # drop new packages between interfaces
        iifname {"${cfg.lan.name}", "${cfg.wan.name}"} oifname {"${cfg.lan.name}", "${cfg.wan.name}"} ct state new counter drop
        accept
      '';

      # https://search.nixos.org/options?channel=unstable&show=networking.nftables.tables
      # This is currently opt in, because we need to benchmark this!
      # Does it improve something?
      nftables.tables.shaping = mkIf config.pi-router.nftables.traffic-shaping {
        enable = true;
        family = "inet";
        name = "shaping";
        content = ''
          chain postrouting {
              type route hook output priority -150; policy accept;
              ip daddr != 192.168.0.0/16 jump wan                               # non LAN traffic: chain wan
              ip daddr 192.168.0.0/16 meta length 1-64 meta priority set 1:11   # small packets in LAN: priority
            }
            chain wan {
              tcp dport 22 meta priority set 1:21 return                       # SSH traffic -> Internet: priority
              tcp dport { 27015, 27036 } meta priority set 1:21 return         # CS traffic -> Internet: priority
              udp dport { 27015, 27031-27036 } meta priority set 1:21 return   # CS traffic -> Internet: priority
              meta length 1-64 meta priority set 1:21 return                   # small packets -> Internet: priority
              meta priority set 1:20 counter                                   # default -> Internet: normal
            }
        '';
      };

    };

    # allow routing between interfaces
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
    };

  };

}
