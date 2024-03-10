default: build fmt test

build env="prod":
    MIX_ENV={{ env }} mix compile
    MIX_ENV={{ env }} mix escript.build

fmt:
    mix format

test *args="":
    mix test {{ args }}

# Start locally with "mix run"
start *args="":
    mix run --no-halt main.exs {{ args }}


release env="prod": test
    # NOTE: you have to bump the version in mix.exs
    MIX_ENV={{ env }} mix release

# Remove builds, deps, caches, etc.
clean:
    mix clean --deps
    rm -rf burrito_out
    rm -rf result
    rm -rf blast
