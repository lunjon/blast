default: build fmt test

build env="prod":
    MIX_ENV={{ env }} mix compile
    MIX_ENV={{ env }} mix escript.build
    nix build

fmt:
    mix format
    biome format . --write

test *args="":
    mix test {{ args }}

check: build test
    biome check .

release env="prod": test
    # NOTE: you have to bump the version in mix.exs
    MIX_ENV={{ env }} mix release

# Remove builds, deps, caches, etc.
clean:
    mix clean --deps
    rm -rf burrito_out
    rm -rf result
    rm -rf blast
