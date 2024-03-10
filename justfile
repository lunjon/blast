default: build fmt test

build:
    mix compile

fmt:
    mix format

test *args="":
    mix test {{ args }}

release env="prod": test
    # NOTE: you have to bump the version in mix.exs
    MIX_ENV={{ env }} mix release

# Remove builds, deps, caches, etc.
clean:
    mix clean --deps
    rm -rf burrito_out
    rm -rf result
    rm -rf blast
