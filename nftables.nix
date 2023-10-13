{ config, ... }:
let cfg = config.pi-router.interfaces; in
{

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
      externalInterface = cfg.lan.name;
      internalInterfaces = [ cfg.wan.name ];
    };

    firewall.extraInputRules = ''
      # ICMP:
      # routers may also want: mld-listener-query, nd-router-solicit
      ip6 nexthdr icmpv6 icmpv6 type {
        destination-unreachable,
        packet-too-big,
        time-exceeded,
        parameter-problem,
        nd-router-advert,
        nd-neighbor-solicit,
        nd-neighbor-advert
      } accept

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

  };
}
