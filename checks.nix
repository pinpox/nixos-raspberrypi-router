{ nixpkgs, modules, ... }: {

  x86_64-linux = let system = "x86_64-linux"; in {
    vmTest =
      let
        publicIP = "10.10.10.1";
        routerIP = "192.168.101.1";
      in
      with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system; };
      makeTest {
        name = "router-test";
        nodes = {

          # simulating the public internet
          public = { pkgs, config, ... }: {
            imports = [
              modules.dhcp
              modules.iperf3
              modules.options
            ];
            pi-router.interfaces.lan = {
              name = "eth1";
              ip = publicIP;
            };
            virtualisation.vlans = [ 1 ];
            networking = {
              interfaces = {
                eth0 = { useDHCP = false; };
                eth1 = {
                  useDHCP = false;
                  ipv4 = {
                    addresses = [{
                      address = "${config.pi-router.interfaces.lan.ip}";
                      prefixLength = 24;
                    }];
                  };
                };
              };
            };
          };

          # the router we are testing
          router = { pkgs, config, ... }: {
            imports = [
              modules.dhcp
              modules.dns
              modules.iperf3
              modules.nftables
              modules.options
            ];
            pi-router = {
              interfaces = {
                wan = { name = "eth1"; };
                lan = { name = "eth2"; ip = routerIP; };
              };
              dhcp.static = [
                {
                  ip = "192.168.101.2";
                  mac = "02:de:ad:be:ef:01";
                }
              ];
              unbound.A-records = { "pi-router.de" = "${config.pi-router.interfaces.lan.ip}"; };
            };
            environment.systemPackages = with pkgs; [ dnsutils ];
            virtualisation.vlans = [ 1 2 ];
            networking = {
              interfaces = {
                eth0 = { useDHCP = false; };
                eth1 = { useDHCP = true; };
                eth2 = {
                  useDHCP = false;
                  ipv4.addresses = [{
                    address = "${config.pi-router.interfaces.lan.ip}";
                    prefixLength = 24;
                  }];
                };
              };
            };
          };

          # client with static DHCP lease
          client = { pkgs, ... }: {
            imports = [ ];
            environment.systemPackages = with pkgs; [ dnsutils ];
            virtualisation.vlans = [ 2 ];
            networking = {
              interfaces = {
                eth0 = { useDHCP = false; };
                eth1 = {
                  useDHCP = true;
                  macAddress = "02:de:ad:be:ef:01";
                };
              };
            };
            systemd.network.networks."40-eth1".dhcpV4Config.ClientIdentifier = "mac";
          };

          # client without static DHCP lease
          client2 = { pkgs, ... }: {
            imports = [ ];
            environment.systemPackages = with pkgs; [ dnsutils ];
            virtualisation.vlans = [ 2 ];
            networking = {
              interfaces = {
                eth0 = { useDHCP = false; };
                eth1 = { useDHCP = true; };
              };
            };
          };

        };
        testScript = ''
          # start the node simulating the public internet
          public.start()
          public.wait_for_unit("network-online.target")

          # start router node
          router.start()

          # do all services start correctly?
          router.wait_for_unit("network-online.target")
          router.wait_for_unit("unbound.service")

          # does the router have internet access? is DHCP working? Does it's DNS server work?
          router.succeed("ping -c 1 ${publicIP}")
          router.wait_until_succeeds("nslookup pi-router.de 127.0.0.1")

          # start the client node
          client.start()
          client.wait_for_unit("network-online.target")

          # does the client reach the router?
          client.succeed("ping -c 1 ${routerIP}")

          # does the client get DNS replies from the router?
          client.succeed("nslookup pi-router.de ${routerIP}")

          # does the client reach the internet? Is NAT working?
          client.succeed("ping -c 1 ${publicIP}")

          # does the static DHCP entry for client work?
          client2.start()
          client2.wait_for_unit("network-online.target")
          client2.succeed("ping -c 1 192.168.101.2")

          # does the client without static DHCP lease work as expected?
          client2.succeed("ping -c 1 ${routerIP}")
          client2.succeed("nslookup pi-router.de ${routerIP}")
          client2.succeed("ping -c 1 ${publicIP}")


          # check if iperf3 works
          client.succeed("${pkgs.iperf}/bin/iperf3 -c ${routerIP} -t 3 -P 4")
          client.succeed("${pkgs.iperf}/bin/iperf3 -c ${routerIP} -t 3 -P 4 -R")
          client.succeed("${pkgs.iperf}/bin/iperf3 -c ${publicIP} -t 3 -P 4")
          client.succeed("${pkgs.iperf}/bin/iperf3 -c ${publicIP} -t 3 -P 4 -R")
        '';
      };
  };

}
