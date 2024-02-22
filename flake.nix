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
      deps = import ./deps.nix {
        lib = pkgs.lib;
        beamPackages = pkgs.beamPackages;
      };
      erlang = pkgs.beam.interpreters.erlang_25;
      elixir = pkgs.beam.interpreters.elixir;
      pname = "blast";
      version = "0.0.0";
      src = ./.;

      mixFodDeps = pkgs.beamPackages.fetchMixDeps {
        pname = "mix-deps-${pname}";
        inherit src version;
        # hash = pkgs.lib.fakeHash;
        hash = "sha256-ZXWXxOUsmih/g4XVfyMJwfTR+qkWZCRMk7SY6UeJfYU=";
      };

    in {
      packages.${system}.default = pkgs.beamPackages.mixRelease rec {
        inherit pname version src mixFodDeps;
        # mixFodDeps = mixDeps;

        # pname = "blast";
        # version = "0.0.0";

        # beamDeps = with deps; [
        #   jason
        #   httpoison
        # ];

        RELEASE_COOKIE = "KAAX37MU6532HG547P4LWXWOKZ63ECSZNLDFNYTUX75ZM2VJ35CA====";
        postBuild = ''
        mkdir -p $out/releases
        echo "KAAX37MU6532HG547P4LWXWOKZ63ECSZNLDFNYTUX75ZM2VJ35CA====" > $out/releases/COOKIE
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
          pkgs.mix2nix
          pkgs.elixir-ls
          next-ls.packages.${system}.default
          lexical-ls.packages.${system}.default
        ];
      };
    };
}
