{
  # Builds the dotfiles installer GUI (installer/) for Linux:
  #   nix run github:Villoh/dotfiles
  # This flake only packages the installer. NixOS/Home Manager owns the
  # system and its packages (see AGENTS.md); chezmoi never deploys this file.
  description = "Villoh/dotfiles installer";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: {
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.installer;
        installer = pkgs.callPackage ./installer/package.nix { };
      });

      apps = forAll (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.installer}/bin/dotfiles-installer";
        };
      });
    };
}
