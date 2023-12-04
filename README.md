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
...

# Send GET http://localhost:8080/path
$ blast --url http://localhost:8080/path
...
```

There are options to control all basic aspects of an HTTP request.

Use `blast --help` to see them all.

## Hooks
`blast` support _hooks_ via external Elixir modules via the `--hooks FILEPATH` option.

This will load a filepath as an elixir file, expecting a single module that exports
zero or more hooks.

A _hook_ is one of the following functions in the module:
- `pre_request(Core.Request.t()) :: Core.Request.t()`: this is called before each request is sent.

### Example

The module defined below exports a `pre_request` hook that adds
an authorization header before each request is sent.

```elixir
# The name of the module is not important.
defmodule Blast.Hooks do
  # Note that the function must be exported (and that the name matters).
  def pre_request(req) do
    # Get token from somewhere
    token = OAuth.get_token()
    bearer = "Bearer #{token}"

    req
    |> Core.Request.put_header("Authorization", bearer)
  end
end
```

