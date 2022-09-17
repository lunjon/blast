# TODO

## Fix
- [ ] Shutdown if invalid URL
- [x] Shutdown if missing --url but giving other flags

## Options/Flags
- Output format flag: `--output`
  - [x] JSON
  - [ ] Plaintext

## Features
- Web interface in Phoenix
  - [ ] Start via `--web` flag
        Probably find this useful: https://elixir-lang.org/getting-started/mix-otp/supervisor-and-application.html#starting-applications
- [ ] Investigate if it's possible to load a module
  - Idea is to allow users to have custom code running, e.g. for authentication.
  - pre- and post-request?
  - Should be using the builtin `Code.require_file`
- [ ] Distributed mode: allow other instance to connect to cluster with `--connect <node>`

## Tests
- [x] Arg parsing
