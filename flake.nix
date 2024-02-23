{
  description = "A basic flake used for development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    next-ls = {
      type = "github";
      owner = "elixir-tools";
      repo = "next-ls";
    };

    lexical-ls = {
      type = "github";
      owner = "lexical-lsp";
      repo = "lexical";
    };
  };

  outputs = { self, nixpkgs, next-ls, lexical-ls }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      erlang = pkgs.beam.interpreters.erlang_26;
      elixir = pkgs.beam.interpreters.elixir;
      pname = "blast";
    in {
      formatter.${system} = pkgs.nixfmt;

      packages.${system}.default = pkgs.beamPackages.mixRelease rec {
        inherit pname;
        version = "0.1.0";
        src = ./.;

        mixFodDeps = pkgs.beamPackages.fetchMixDeps {
          pname = "${pname}-deps";
          inherit src version;
          hash = "sha256-ZXWXxOUsmih/g4XVfyMJwfTR+qkWZCRMk7SY6UeJfYU=";
        };

        fixupPhase = ''
          mkdir -p $out/releases
          echo "71249ecf-ef39-4d7b-9e19-19c861dc495e" > $out/releases/COOKIE
        '';
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "blast";
        shellHook = ''
          exec $SHELL
        '';

        packages = [
          erlang
          elixir

          pkgs.nil
          pkgs.elixir-ls
          next-ls.packages.${system}.default
          lexical-ls.packages.${system}.default
        ];
      };
    };
}
