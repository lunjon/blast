# TODO

## Fix

## Features
- [ ] Strategy: configure how to ramp up request frequence, etc.
  - [ ] What should the options be? `--strategy <expression>`?
  - [ ] Types of strategies:
    - max (default?): send as many requests as possible per worker
    - rampup: increase load over time. Questions:
      What do we ramp up: workers? total request frequency?
- [ ] Distributed mode
- Web interface in Phoenix
  - [ ] Start via `--web` flag
        Probably find this useful: https://elixir-lang.org/getting-started/mix-otp/supervisor-and-application.html#starting-applications
- [ ] Investigate if it's possible to load a module
  - Idea is to allow users to have custom code running, e.g. for authentication.
  - pre- and post-request?
  - Should be using the builtin `Code.require_file`

## Escript
- Output format flag: `--output`
  - [ ] Add flag
  - [ ] JSON
  - [ ] Plaintext
