{
  description = "A melted flake from the blast";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      erlang = pkgs.beam.packages.erlang_26;
      elixir = pkgs.beam.packages.erlang_26.elixir_1_16;
    in
    {
      formatter.${system} = pkgs.nixfmt;

      packages.${system}.default = erlang.callPackage ./blast.nix { inherit elixir; };

      devShells.${system}.default = pkgs.mkShell {
        name = "blast";
        shellHook = ''
          exec nu
        '';

        packages = [
          erlang.erlang
          elixir

          # Language servers
          pkgs.nil
          pkgs.elixir-ls
        ];
      };
    };
}
