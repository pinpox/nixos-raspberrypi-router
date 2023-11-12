{ pkgs, config, ... }:
let
  cfg = config.pi-router;
in
{

  config = {

    # Define a user account.
    users.users.root = {
      openssh.authorizedKeys.keyFiles = [
        (pkgs.fetchurl {
          url = "https://github.com/MayNiklas.keys";
          sha256 = "sha256-QW7XAqj9EmdQXYEu8EU74eFWml5V0ALvbQOnjk8ce/U=";
        })
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
      iftop # display bandwidth usage on a network interface
      iperf3 # speedtest between 2 devices
      ppp # for some manual debugging of pppd
      speedtest-cli # speedtest.net from the command line
      tcpdump # view network traffic
      traceroute # tracks the route taken by packets over an IP network
    ];

    # changing some settings for htop makes it more useful for our use case as a router
    programs.htop = {
      enable = true;
      settings = {
        # important since we want to see our networking stack
        hide_kernel_threads = false;
        hide_userland_threads = false;
        # helpful for keeping an eye on temperatures
        show_cpu_frequency = true;
        show_cpu_temperature = true;
      };
    };

    # Time zone and internationalisation
    time.timeZone = "Europe/Berlin";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "de";
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

    # Nix settings
    nix = {
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
        # Free up to 1GiB whenever there is less than 100MiB left.
        min-free = ${toString (100 * 1024 * 1024)}
        max-free = ${toString (1024 * 1024 * 1024)}
      '';

      settings = {
        # Save space by hardlinking store files
        auto-optimise-store = true;
        allowed-users = [ "root" ];
      };

      # Clean up old generations after 30 days
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };

    system.stateVersion = "23.05";

    # Hardware-specific settings

    # Workaround for failing module. See PR
    nixpkgs.overlays = [
      (final: super: {
        makeModulesClosure = x:
          super.makeModulesClosure (x // { allowMissing = true; });
      })
    ];

    # Enable serial console on GPIO pins
    boot.kernelParams = [ "console=ttyS1,115200n8" ];

    # Required for the Wireless firmware
    # hardware.enableRedistributableFirmware = true;

    # CPU profile
    # powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  };
}
