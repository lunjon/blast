## Fix

## Features
- Management API
  - Web interface in Phoenix
- [ ] Investigate if it's possible to load a module
  - Idea is to allow users to have custom code running, e.g. for authentication.
  - pre- and post-request?
  - Should be using the builtin `Code.require_file`

## CLI
- [ ] Output results when exiting
- Output format flag: `--output`
  - [ ] Add flag
  - [ ] JSON
  - [ ] Plaintext

## Pyro
- [ ] Add required parameter: address to server
- Options on start
  - [ ] port
  - [ ] verbose
