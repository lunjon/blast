default: build fmt test

build:
    mix compile
    cd apps/cli && mix escript.build

fmt:
    mix format

test:
    mix test

install: build
    cd apps/cli && mix escript.install
