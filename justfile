alias t := test

build:
    cd blast && mix compile

test:
    cd blast && mix test

install: build
    cd blast/apps/cli && mix escript.install
