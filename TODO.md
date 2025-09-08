# TODOs

## [WIP] Web UI

### Styling
- [ ] Change button color depending on idle/running

## Blastfile

Require a `use Blastfile` in the blast module that uses `def __macro__` to inject some code.
- [ ] Function for setting headers: `put_header(req, name, value) -> req`

## HTTP controller
- Rules: support rules that apply for some circumstances that affects when running load tests:
  - 5XX status: add option for controlling how to handle these
  - 4XX status: add option for controlling how to handle these
  - 429 Too Many Requests: this should be respected by default
