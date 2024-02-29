default: build fmt test

build:
    mix compile

fmt:
    mix format

test:
    mix test

run *args:
    MIX_ENV=prod mix run --no-halt -- {{ args }}

release env="prod": test
    # NOTE: you have to bump the version in mix.exs
    MIX_ENV={{ env }} mix release

clean:
    rm -rf burrito_out
    mix clean --deps
