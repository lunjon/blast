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
- `init() :: {:ok, map()}`: this is called once on start up.
  - the map returned from this function will be passed to other hooks\
    as the first argument.
  - If this function isn't defined an empty map will be provided for other hooks
  - This is referred to as the _context_
- `pre_request(map(), Core.Request.t()) :: {map(), Core.Request.t()}`: this is called before each request is sent.
  - The first argument is the context returned from `init`
  - It should return a tuple containing the context and request
  - The context returned here will be sent the next time

### Example

The module defined below exports a `pre_request` hook that adds
an authorization header before each request is sent.

```elixir
# The name of the module is not important.
defmodule Blast.Hooks do
  alias Core.Request

  # Note that the function must be exported (and that the name matters).
  def pre_request(cx, req) do
    {cx, token} = get_token(cx, cx.token)
    bearer = "Bearer #{token}"

    req = Request.put_header(req, "Authorization", bearer)

    {cx, req}
  end

  defp get_token(cx, nil) do
    token = OAuth.get_token()
    {Map.put(cx, :token, token), token}
  end

  defp get_token(cx, token), do: {cx, token}
end
```

