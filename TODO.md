# TODOs

## [WIP] Web UI

### Module/server for application state
- This should hold the current state of the application; started, stopped, etc.
- Should this also hold the responsibility of the Collector?
- [x] GenServer that's started as part of the application
- [x] Register runtime configuration: base url, requests

### Web server
- [ ] Show current state: running/stopped
- [ ] Show base URL
- [ ] Show requests

## HTTP controller
- Rules: support rules that apply for some circumstances that affects when running load tests:
  - 5XX status: add option for controlling how to handle these
  - 4XX status: add option for controlling how to handle these
  - 429 Too Many Requests: this should be respected by default
