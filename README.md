# Blast

Load test framework, written in Elixir, that targets HTTP APIs.

## Installation and Usage

### Installation

In order to install you need Elixir 1.13+.

Then run the following commands:
```sh
$ cd blast && mix deps.get
$ cd apps/cli && mix escript.install
```

Make sure you have `~/.mix/escripts/` in your `$PATH` environment variable.

### Usage

After installing, you should be able to invoke the cli:

```sh
$ blast -h
```
