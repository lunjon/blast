# TODO

## Fix
- [ ] Output results when exiting

## Features
- Controlling server
  - Command-line client: connect to running node and use REPL to control
  - Web interface in Phoenix
- [ ] Investigate if it's possible to load a module
  - Idea is to allow users to have custom code running, e.g. for authentication.
  - pre- and post-request?
  - Should be using the builtin `Code.require_file`

## Escript
- Output format flag: `--output`
  - [ ] Add flag
  - [ ] JSON
  - [ ] Plaintext
