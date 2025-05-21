# Blast

Load test framework, written in Elixir, that targets HTTP APIs.

## Running

It is currently only supported running from your shell.
You have the following options.

**escript**
Build the escript using `just build`, then use the artifact like so:
```sh
./blast -h
```

**nix**
With nix installed you can run:
```sh
nix run "." -- <args>
```

This will use the escript available.

When started a simple non-interactive TUI will appear that renders the status
of the application: requests per second, which requests are sent, etc.

However, to be able to start `blast` you need a _spec file_.

### Spec file

The _spec file_ defines which requests to send and is written in YAML.
By default blast will lock for `blast.y[a]ml` in the current working directory,
but you can point to another file with the `--specfile` option.

**Example**:
```yaml
base-url: http://localhost:8080
requests:
  - path: "/test"
  - path: "/withbody"
    method: post
    body: "{\"test\": true}"
    headers:
      - name: content-type
        value: application/json
```

You can read more about it in the [docs](./docs/specfile.md).

### Hooks
Blast support _hooks_ via external Elixir modules using the `--hooks FILEPATH` option.

This will load a filepath as an elixir file, expecting a single module that exports
zero or more hooks.

You can read more about it in the [docs](./docs/hooks.md).

## Logs
`blast` creates and writes logs to the file `blast.log` in cwd.

## Development

I recommend using the nix flake, like so:

```sh
$ nix develop # It takes a while the first time
...
$ mix deps.get # Fetch dependencies
```

### Running as application

You can start blast using:
```sh
$ mix run --no-halt main.exs [ARGS]
```
