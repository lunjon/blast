{
  description = "A flake used for development";

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
      erlang = pkgs.beam.packages.erlang_26;
      elixir = pkgs.beam.packages.erlang_26.elixir_1_16;
    in {
      formatter.${system} = pkgs.nixfmt;

      packages.${system}.default =
        erlang.callPackage ./blast.nix { inherit elixir; };

      devShells.${system}.default = pkgs.mkShell {
        name = "blast";
        shellHook = ''
          exec $SHELL
        '';

        packages = [
          erlang.erlang
          elixir

          # Language servers
          pkgs.nil
          pkgs.elixir-ls
          next-ls.packages.${system}.default
          lexical-ls.packages.${system}.default
        ];

        LOCALE_ARCHIVE = /usr/lib/locale/locale-archive;
      };
    };
}
