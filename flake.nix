{
  description = "Router based on the Raspberry Pi Compute Module 4";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      # nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in
    {

      nixosModules = builtins.listToAttrs (map
        (x: {
          name = x;
          value = import (./modules + "/${x}");
        })
        (builtins.attrNames (builtins.readDir ./modules)));

      # nixosModules.mymodule = { config, pkgs, lib, ... }: { };

      nixosConfigurations.nixos-router = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./configuration.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          { imports = builtins.attrValues self.nixosModules; }
          {

            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
            nix.registry.nixpkgs.flake = nixpkgs;
            sdImage.compressImage = false;
            sdImage.imageBaseName = "raspi-image";
          }
        ];
      };

      packages = forAllSystems (system:
        rec {
          # Generate a sd-card image for the pi
          # nix build '.#raspi-image'
          raspi-image =
            self.nixosConfigurations.nixos-router.config.system.build.sdImage;
          default = raspi-image;
        });

      # nix run .\#checks.x86_64-linux.vmTest.driver
      checks = import ./checks.nix { nixpkgs = nixpkgs; modules = self.nixosModules; };

    };
}
