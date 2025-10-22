check: fmt test
    biome check .

build env="prod":
    MIX_ENV={{ env }} mix compile
    MIX_ENV={{ env }} mix escript.build
    nix build

fmt:
    mix format
    biome format . --write

test *args="":
    mix test {{ args }}

# Remove builds, deps, caches, etc.
clean:
    mix clean --deps
    rm -rf burrito_out
    rm -rf result
    rm -rf blast
