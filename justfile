alias t := test

all:
    mix all
    mix test

build:
    mix compile
    mix escript.build

test:
    mix test

install: build
    cp blast ~/.local/bin/blast
