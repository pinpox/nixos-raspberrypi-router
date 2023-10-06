{ config, pkgs, lib, ... }: {

  imports = [ ];

  config = {

    # Hardware-specific settings

    # Required for the Wireless firmware
    hardware.enableRedistributableFirmware = true;

    powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

    boot = {

      # kernelParams = [ "console=ttyS1,115200n8" ];

      loader = {
        raspberryPi = {
          firmwareConfig = ''
            dtparam=poe_fan_temp0=50000
            dtparam=poe_fan_temp1=60000
            dtparam=poe_fan_temp2=70000
            dtparam=poe_fan_temp3=80000
          '';
        };
      };
    };

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
    time = { timeZone = "Europe/Berlin"; };

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "de";
    };

    # Networking and SSH
    networking = {
      hostName = "nixos-router";
      interfaces.eth0 = { useDHCP = true; };
    };


    services.openssh = {
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      enable = true;
      startWhenNeeded = true;
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

    boot.initrd.availableKernelModules = [ "usbhid" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    # Use 1GB of additional swap memory in order to not run out of memory
    # when installing lots of things while running other things at the same time.
    # swapDevices = [{ device = "/swapfile"; size = 1024; }];
    swapDevices = [ ];

    ##############################

    # boot.kernelPackages = pkgs.linuxPackages_rpi3;
    environment.systemPackages = with pkgs; [

      # Needed for operation
      libraspberrypi

      # Optional, for development
      git

    ];

    # File systems configuration for using the installer's partition layout
    # fileSystems = {
    #   "/boot" = {
    #     device = "/dev/disk/by-label/NIXOS_BOOT";
    #     fsType = "vfat";
    #   };
    #   "/" = {
    #     device = "/dev/disk/by-label/NIXOS_SD";
    #     fsType = "ext4";
    #   };
    # };

    # boot.supportedFilesystems = ["ext4"];

    # Preserve space by sacrificing documentation and history
    # documentation.nixos.enable = false;
    # boot.cleanTmpDir = true;

    system.stateVersion = "23.11";

  };
}
