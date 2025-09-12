# Blast

Load test framework, written in Elixir, that targets HTTP APIs.

## Running

You will need to install Elixir v1.18+ in order to run blast.

#### mix
This is what `main.exs` is for:
```sh
mix run main.exs -h
```

#### escript
Build the escript using `just build`, then use the artifact like so:
```sh
./blast -h
```

#### nix
With nix installed you can run:

```sh
nix run "." -- -h
```

or

```sh
nix develop
just build
./blast -h # escript
```

When started a simple web interface is started on [localhost:4000](http://localhost:4000).
However, to be able to start `blast` you need to configure it.

## Configuration

The configuration is done through an Elixir module in a file you specify.
A minimal example looks something like this:

```elixir
defmodule Blast do
  # This is the first required function.
  # It must return a valid URL to be used as the base for the requests.
  def base_url() do
    "https://myapi.example"
  end

  # This is the second required function.
  # It must return a non-empty list of maps that specifies the requests to send.
  def requests() do
    [
      %{
        method: "get",
        path: "/resource" # all paths are relative to the base URL.
      }
    ]
  end
end
```

> [!NOTE]
> Don't know Elixir? Don't worry! The syntax is very simple.


By default blast will look for a `blast.ex[s]` file in the current working directory,
but you can specify a location with the `-f/--blastfile` option.

You can read more about it in the [docs](./docs/blast.md).

### Options

Here a small breakdown of the most important options that you need
in order to run blast. The module, and sometimes function definitions
will be omitted for brewity.

#### Base URL
All requests are specified by atleast method and path, where path is relative to the base URL:
```elixir
def base_url() do
  "http://myapi.cool"
end
```

#### Method and path
Requests are given by the `requests()` function:
```elixir
def requests() do
  [
    %{method: "get", path: "/resource/path"},
    %{method: "get", path: "/testing?fail=true"},
  ]
end
```

The `%{}` syntax is a _map_ in Elixir, and each request requires atleast:
- `method`: HTTP method, lower case or upper case.
- `path`: Relative path of the request URL.


#### Headers
HTTP Headers can be specified per request using the `headers` key:
```elixir
%{
  method: "get",
  path: "/testing",
  headers: [
    # These are called tuples.
    {"name1", "value1"},
    {"name2", "value2"},
  ]
}
```

#### Default headers
HTTP Headers to include for every request can be specified with the `default_headers()` function:
```elixir
# This should return a list of two-element tuples.
def default_headers() do
  [
    # These are called tuples
    {"name1", "value1"},
    {"name2", "value2"},
  ]
end
```

For a full specification of the blast module see the [docs](./docs/blast.md).

## Logs
`blast` creates and writes logs to the file `blast.log` in cwd.

## Development

I recommend using the nix flake, like so:

```sh
nix develop # It takes a while the first time
...

mix deps.get # Fetch dependencies

iex -S mix   # Start the application in IEx
```
