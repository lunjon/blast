default: fmt build test

build:
    mix
    mix escript.build

fmt:
    mix format

test:
    mix test

install: build
    cp blast ~/.local/bin/blast
