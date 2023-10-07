{ pkgs, ... }: {

  imports = [
    ./ssh.nix
    ./nixos.nix
    ./hardware.nix
  ];

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

    # Time zone and internationalisation
    time.timeZone = "Europe/Berlin";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "de";
    };

    # Networking
    networking = {
      usePredictableInterfaceNames = true;
      hostName = "nixos-router";
      # interfaces.eth0 = { useDHCP = true; };
    };
  };
}
