default: build fmt test

build:
    cd blast && mix compile
    cd blast/apps/cli && mix escript.build

fmt:
    cd blast && mix format

test:
    cd blast && mix test

install: build
    cd blast/apps/cli && mix escript.install
