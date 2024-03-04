default: build fmt test

build:
    mix compile

fmt:
    mix format

test:
    mix test

release env="prod": test
    # NOTE: you have to bump the version in mix.exs
    MIX_ENV={{ env }} mix release

clean:
    mix clean --deps
    rm -rf burrito_out
