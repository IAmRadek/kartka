{
  description = "Kartka, a minimal plain text editor for macOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        kartka = pkgs.callPackage ./nix/package.nix { };
        default = self.packages.${system}.kartka;
      };

      overlays.default = final: prev: {
        kartka = final.callPackage ./nix/package.nix { };
      };
    };
}
