default: build fmt test

build:
    mix compile

fmt:
    mix format

test:
    mix test

release env="prod": build
    MIX_ENV={{ env }} mix release
