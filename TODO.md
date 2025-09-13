# TODOs

## [WIP] Web UI

### Styling
- [x] Change button color depending on idle/running

## HTTP controller
- Rules: support rules that apply for some circumstances that affects when running load tests:
  - 5XX status: add option for controlling how to handle these
  - 4XX status: add option for controlling how to handle these
  - 429 Too Many Requests: this should be respected by default
