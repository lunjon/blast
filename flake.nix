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
      erlang = pkgs.beam.interpreters.erlang_26;
      elixir = pkgs.beam.interpreters.elixir;
    in {
      formatter.${system} = pkgs.nixfmt;

      devShells.${system}.default = pkgs.mkShell {
        name = "blast";
        shellHook = ''
          exec $SHELL
        '';

        packages = [
          erlang
          elixir

          pkgs.xz
          pkgs.zig

          pkgs.nil
          pkgs.elixir-ls
          next-ls.packages.${system}.default
          lexical-ls.packages.${system}.default
        ];
      };
    };
}
