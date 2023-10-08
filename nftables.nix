{ config, pkgs, lib, ... }:
let

  nft-ruleset = {
    nftables = [
      # { flush.ruleset = null; }
      {
        add.table = {
          family = "inet";
          name = "mytable";
        };
      }
      {
        add.chain = {
          family = "inet";
          name = "mychain";
          table = "mytable";
        };
      }
      {
        add.rule = {
          family = "inet";
          chain = "mychain";
          table = "mytable";
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
                right = 2222;
              };
            }
            { accept = null; }
          ];
        };
      }
    ];
  };

in
{
  networking.nftables.enable = true;

  networking.firewall.allowedTCPPorts = [ 7777 ];
  networking.firewall.allowedUDPPorts = [ 8888 ];

  # systemd.services.nftables.requires = [ "nftables-extrarules.service" ];

  systemd.services.nftables-extrarules = {
    description = "nftables firewall extra rules";
    after = [ "nftables.service" ];
    requiredBy = [ "nftables.service" ];
    partOf = [ "nftables.service" ];
    reloadIfChanged = true;
    serviceConfig =
      let

        ruleset-json = pkgs.writeTextFile {
          name = "ruleset.json";
          text = (builtins.toJSON nft-ruleset);
        };

        nftables-start = pkgs.writeShellScript "nftables-start" ''
          # ${pkgs.nftables}/bin/nft flush ruleset
          ${pkgs.nftables}/bin/nft --json -f ${ruleset-json}
        '';

      in
      {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = nftables-start;
        ExecStartPre = pkgs.writeShellScript "nftables-start-pre" "${pkgs.nftables}/bin/nft --check --json --file ${ruleset-json}";
        # TODO should we do something better for reload and stop?
        ExecReload = nftables-start;
        # ExecStop = "${pkgs.nftables}/bin/nft flush ruleset";
      };
  };

}
