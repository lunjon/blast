# Hooks

A _hooks_ file can be loaded using the `--hooks FILEPATH` option.

This will load a filepath as an elixir file, expecting a single module that exports
zero or more _hooks_. A _hook_ is a function that gets in one of the lifecycles
of the application.

### init

The `init` function has the signature: `init() :: {:ok, map()}`

This is called _once_ on start up:
- the map returned from this function will be passed to other hooks as the first argument.
- If this function isn't defined an empty map will be provided for other hooks.
- This is referred to as the _context_.

### on_start

The `on_start` function has the signature: `on_start(map()) :: {:ok, map()}`

This is called once _per worker_ when starting:
- the argument will be a map, either an empty or the one returned from `init` (if it was defined).
- It should return a tuple with the `:ok` atom and the context

### on_request

The `on_request` function has the signature: `on_request(map(), Blast.Request.t()) :: {map(), Blast.Request.t()}`

This gets called, if defined, before each request is sent:
- The first argument is the context returned from `init` and/or `on_start`
- It should return a tuple containing the context and request
- The context returned here will be sent the next time

This hook is useful for setting e.g more dynamic content such as authentication
headers. The context is returned because it can be altered here as well.

## Example

The module defined below exports `init` and `on_request` hook that adds
an authorization header before each request is sent.

```elixir
# The name of the module is not important.
defmodule Blast.Hooks do
  alias Blast.Request

  # This is called once before anything else starts.
  def init() do
    {:ok, %{awesome: true}}
  end

  # Note that the function must be exported (and that the name matters).
  def on_request(cx, req) do
    {cx, token} = get_token(cx, cx.token)
    bearer = "Bearer #{token}"

    req = Request.put_header(req, "Authorization", bearer)

    {cx, req}
  end

  defp get_token(cx, nil) do
    token = "..."
    {Map.put(cx, :token, token), token}
  end

  defp get_token(cx, token), do: {cx, token}
end
```

