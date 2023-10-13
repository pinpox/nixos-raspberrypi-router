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
    nftables = {
      enable = true;
      ruleset = ''
        define LAN_IFC = { "${cfg.lan.name}" }
        define LAN_NET = { ${cfg.lan.ip}/24 }

        define WAN_IFC = { "${cfg.wan.name}" }

        define ALL_IFC = { "${cfg.lan.name}", "${cfg.wan.name}" }

        table inet filter {
            # Block all incomming connections traffic except SSH and "ping" and DNS.
            chain input {
                type filter hook input priority 0;

                # accept any localhost traffic
                iifname lo accept

                # accept traffic originated from us
                ct state {established, related} accept

                # ICMP
                # routers may also want: mld-listener-query, nd-router-solicit
                ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
                ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem } accept

                # allow "ping"
                ip6 nexthdr icmpv6 icmpv6 type echo-request accept
                ip protocol icmp icmp type echo-request accept

                # allow SSH
                tcp dport 22 accept

                # allow DNS via LAN
                iifname $LAN_IFC tcp dport {53} accept
                iifname $LAN_IFC udp dport {53} accept

                # allow DHCP via LAN
                iifname $LAN_IFC udp dport {67} accept

                # count and drop any other traffic
                counter drop
            }

            # Allow all outgoing connections.
            chain output {
                type filter hook output priority 0;
                accept
            }

            chain forward {
                type filter hook forward priority 0;
              
                # allow LAN to WAN
                iifname $LAN_IFC oifname $WAN_IFC accept

                # drop new packages between interfaces
                iifname $ALL_IFC oifname $ALL_IFC ct state new counter drop

                accept
            }
        }

        table ip nat {
            chain PREROUTING {
                type nat hook prerouting priority dstnat; policy accept;
            }

            chain INPUT {
                type nat hook input priority 100; policy accept;
            }

            chain OUTPUT {
                type nat hook output priority -100; policy accept;
            }

            chain POSTROUTING {
                type nat hook postrouting priority srcnat; policy accept;

                # NAT between LAN and WAN
                oifname $WAN_IFC ip saddr $LAN_NET counter masquerade
            }
        }
      '';
    };
  };
}
