alias t := test

default: build fmt test

build:
    cd blast && mix compile

fmt:
    cd blast && mix format

test:
    cd blast && mix test

install: build
    cd blast/apps/cli && mix escript.install
    cd blast/apps/pyro && mix escript.install
