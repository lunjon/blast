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
```

`blast` is an application that requires human interaction and is not intended to
be called from other scripts. As such, when running `blast` you will enter it's
prompt:

```sh
$ blast
[running] blast>
```

This is a REPL (read-eval-print-loop) that allows you to control and
configure it, as well as monitor it's status.

#### Blast file

Blast needs a *blast file* that defines what requests to send.
The specfile is written in YAML and can be specified using `--spec-file` flag.
If not specified it looks for a `blast.y[a]ml` in the current working directory.

**Example**:
```yaml
endpoints:
  - base-url: http://localhost:8080
    requests:
      - path: "/test"
      - path: "/withbody"
        method: post
        body: "{\"test\": true}"
        headers:
          - name: content-type
            value: application/json
```

You can read more about it in [docs](./docs/blastfile.md).

## Hooks
`blast` support _hooks_ via external Elixir modules using the `--hooks FILEPATH` option.

This will load a filepath as an elixir file, expecting a single module that exports
zero or more hooks.

You can read more about it in [docs](./docs/hooks.md).
