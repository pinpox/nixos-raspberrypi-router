{ config, pkgs, lib, ... }:
let
  nft-ruleset =
    {
      nftables = [
        { flush = { ruleset = null; }; }
        {
          add = {
            table = {
              family = "inet";
              name = "mytable";
            };
          };
        }
        {
          add = {
            chain = {
              family = "inet";
              name = "mychain";
              table = "mytable";
            };
          };
        }
        {
          add = {
            rule = {
              chain = "mychain";
              expr = [
                {
                  match = {
                    left = {
                      payload = {
                        field = "dport";
                        protocol = "tcp";
                      };
                    };
                    op = "==";
                    right = 22;
                  };
                }
                { accept = null; }
              ];
              family = "inet";
              table = "mytable";
            };
          };
        }
      ];
    };


  # {
  #   "nftables": [
  #     {
  #       "flush": {
  #         "ruleset": null
  #       }
  #     },
  #     {
  #       "add": {
  #         "table": {
  #           "family": "inet",
  #           "name": "mytable"
  #         }
  #       }
  #     },
  #     {
  #       "add": {
  #         "chain": {
  #           "family": "inet",
  #           "table": "mytable",
  #           "name": "mychain"
  #         }
  #       }
  #     },
  #     {
  #       "add": {
  #         "rule": {
  #           "family": "inet",
  #           "table": "mytable",
  #           "chain": "mychain",
  #           "expr": [
  #             {
  #               "match": {
  #                 "op": "==",
  #                 "left": {
  #                   "payload": {
  #                     "protocol": "tcp",
  #                     "field": "dport"
  #                   }
  #                 },
  #                 "right": 22
  #               }
  #             },
  #             {
  #               "accept": null
  #             }
  #           ]
  #         }
  #       }
  #     }
  #   ]
  # }

in
{
  networking.nftables.enable = true;

  systemd.services.nftables = lib.mkForce {
    description = "nftables firewall";
    before = [ "network-pre.target" ];
    wants = [ "network-pre.target" ];
    wantedBy = [ "multi-user.target" ];
    reloadIfChanged = true;
    serviceConfig =
      let

        ruleset-json = pkgs.writeTextFile {
          name = "ruleset.json";
          text = (builtins.toJSON nft-ruleset);
        };

        # check-script = pkgs.writeShellScript {
        #   name = "nftables-check";
        #   text = "${pkgs.nftables}/bin/nft --check --file ${ruleset-json}";
        #   executable = true;
        # };

        # start-script = pkgs.writeShellScript {
        #   name = "nftables-start";
        #   text = ''
        #     ${pkgs.nftables}/bin/nft flush ruleset
        #     ${pkgs.nftables}/bin/nft -f --json ${ruleset-json}
        #   '';
        #   executable = true;
        # };

        # checkPhase = lib.optionalString cfg.checkRuleset ''
        #   cp $out ruleset.conf
        #   ${cfg.preCheckRuleset}
        #   export NIX_REDIRECTS=/etc/protocols=${pkgs.buildPackages.iana-etc}/etc/protocols:/etc/services=${pkgs.buildPackages.iana-etc}/etc/services
        #   LD_PRELOAD="${pkgs.buildPackages.libredirect}/lib/libredirect.so ${pkgs.buildPackages.lklWithFirewall.lib}/lib/liblkl-hijack.so" \
        #     ${pkgs.buildPackages.nftables}/bin/nft --check --file ruleset.conf
        # '';



        nftables-start = pkgs.writeShellScript "nftables-start" ''
          ${pkgs.nftables}/bin/nft flush ruleset
          ${pkgs.nftables}/bin/nft -f --json ${ruleset-json}
        '';


      in
      {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = nftables-start;

        ExecStartPre = pkgs.writeShellScript "nftables-start-pre" ''
          ${pkgs.nftables}/bin/nft --check --file ${ruleset-json}
        '';

        # ExecReload = "${pkgs.nftables}/bin/nft --check --json --file ${ruleset-json}";
        # ExecReload = start-script;
        ExecStop = "${pkgs.nftables}/bin/nft flush ruleset";
      };
  };
}
