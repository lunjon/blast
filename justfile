default: build fmt test

build:
    mix compile

fmt:
    mix format

test:
    MIX_ENV=test mix test

release env="prod": build
    MIX_ENV={{ env }} mix release
