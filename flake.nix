{
  description = "TODO";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
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

      # nixosModules.photobooth = { config, pkgs, lib, ... }: {
      #   systemd.services.photobooth = {
      #   };
      # };

      nixosConfigurations.photobooth-pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./configuration.nix
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
            self.nixosConfigurations.photobooth-pi.config.system.build.sdImage;
          # inherit (nixpkgsFor.${system}) hello;

          default = raspi-image;
        });
    };
}
