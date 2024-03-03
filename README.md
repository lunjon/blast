# Blast

Load test framework, written in Elixir, that targets HTTP APIs.

It is currently only able to run from the command line,
but I have plans to integrate it into a web-based interface 
built in [Phoenix](https://www.phoenixframework.org/) (inspired by [Locust](https://locust.io)).

## Installation

TODO.

## Spec file

Blast needs a *spec file* that defines which requests to send.
The specfile is written in YAML and can be specified using `--specfile` flag.
If not specified it looks for a `blast.y[a]ml` in the current working directory.

In this file you'll define the requests to send and other options.

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

## Hooks
Blast support _hooks_ via external Elixir modules using the `--hooks FILEPATH` option.

This will load a filepath as an elixir file, expecting a single module that exports
zero or more hooks.

You can read more about it in the [docs](./docs/hooks.md).

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
$ mix run --no-halt -- [ARGS]
```
