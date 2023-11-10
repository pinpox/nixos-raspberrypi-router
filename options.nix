# central module keeping all the options
# this makes them accessible for isolated tests
{ pkgs, lib, config, ... }: {

  options.pi-router = with lib;{
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

}
