{
  description = "A melted flake from the blast";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      erlang = pkgs.beamMinimal27Packages.erlang;
      elixir = pkgs.beamMinimal27Packages.elixir;
    in
    {
      formatter.${system} = pkgs.nixfmt;

      packages.${system}.default = pkgs.beamMinimal27Packages.callPackage ./blast.nix { inherit elixir; };

      devShells.${system}.default = pkgs.mkShell {
        name = "blast";
        shellHook = ''
          exec nu
        '';

        packages = [
          erlang
          elixir
          pkgs.just
          pkgs.nil
          pkgs.elixir-ls
          pkgs.typescript-language-server
        ];
      };
    };
}
