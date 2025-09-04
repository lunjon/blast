# Blast

The _blast file_ defines, as a minimum, an endpoint and the requests to send.
It is written in a standalone file that defines an Elixir module.

For brewity the module definition and, sometimes, function definitions will be omitted for brewity.

This means that all functions lives inside an Elixir module:
```elixir
# The name of the module is not important.
defmodule Blast do
  # ...
end
```

### base_url()

The `base_url()` function is required must return a string to use a base URL for the requests.

```elixir
def base_url() do
  "https://myapi.example"
end
```

### requests()

The `requests()` function is required must return a list of maps that adhere to the following definition:

```elixir
def requests() do
  [
    %{
      method: "get",             #  string (required). HTTP method specified as string.
      path: "/relative",         #  string (required). URL path relative from the base URL.
      headers: [                 # list (optional). List of two-element tuples of strings.
        {"header1", "value1"},
        {"header2", "value2"},
      ],

      # Only one of the body* fields can be specified. All are optional
      body: "string",            # string | map | list. A string to send in the request body.
      file: "filepath"      # string. File path to body to send as request body.
      form: [               # list. List of two-element tuples of name-value pairs.
        {"name1", "value1"},
      ],
      weight: 2,                 # integer (>= 0, default: 1). Makes a request more likely to occurr.
    }
  ]
end
    ```

### default_headers()

This can be used to add HTTP headers to all the requests.
The should be specified exactly as headers in a request map.

```elixir
def default_headers() do
  [
    {"Accept", "*/*"},
  ]
end
```

### settings()

Additional settings can be specified via the `settings()` function.
The function, if defined, must return a map that adhere to the following specification.

```elixir
def settings() do
  %{
    control: %{
      # The `control` object requires two fields: kind and properties.
      kind: "rampup",  # Only support kind is currently "rampup."
      properties: %{   # These are specified below.
        # ...
      }
    }
  }
end
```


By default, i.e when omitting from `settings`, blast will start all workers and send at full capacity right from the start.
But if you like you could instead configure e.g a rampup, which increases requests over time.

#### Rampup

```elixir
# The map returned from settings.
%{
  control: %{
    kind: "rampup",
    properties: %{
      add: 1,      # integer (min: 1, max: 10). How many workers to add after `every` seconds.
      every: 10,   # integer (min: 5, max: 300). How often to add more workers specified in seconds.
      start: 5,    # integer (default: 1, min: 1, max: 100). How many workers to start with.
      target: 20,  # integer (min: 5, max: 10000). The number of workers to reach.
    }
  }
}
```

In the example above, it means:
- starting with 10 workers
- add 2 workers every 10 seconds
- until we reach 100 workers


## Hooks

Blast also support _hooks_. A hook is a function that gets called on one of the lifecycles of the application and/or requests.

Here's a module that defines the supported hooks.


```elixir
defmodule Blast do
  alias Blast.Request

  # Required callbacks omitted.

  # This callback, or hook, is invoked once before all requests are sent.
  # It can be used to setup some initial state, or as blast call it: context.
  # The context is typically a map, but it can be any type you want.
  #
  # If this isn't defined blast will use an empty map as a context.
  def init() do
    context = %{timestamp: Time.utc_now()}
    {:ok, context}
  end

  # The start() method can be used to do something for each worker that starts.
  # Thus it is called once per worker before it starts sending requests.
  #
  # It receives the context created by the init() function.
  def start(context) do
    # Do something with context.
    context
  end

  # This is invoked per worker before each request is sent.
  # It receives two paramters:
  #   context: the one returned from the init() hook, otherwise an empty map (%{}) if init() wasn't defined.
  #   request: the request before being sent. This is the type defined by the Blast.Request module.
  #
  # This function must return a two-element tuple:
  #   {context, request}
  #
  # That is, it must return the context and request.
  def pre_request(cx, req) do
    {cx, token} = update_context(cx)
    req = Request.put_header(req, "Authorization", "Bearer #{token}")
    {cx, req}
  end

  defp get_token() do
    # Some code to get a token for authentication ...
    "..."
    |> String.trim(token)
  end
end
```


## Examples

Check the [examples](../examples) directory to get a better feeling for how a blast module can be written.
