# TODOs

- Publish release artifacts
  - Build using Burrito
- Ramp up: ability to configure/set any way to ramp up requests
  - Perhaps different strategies (start easy though)
    - Add one worker per unit of time
    - Increase frequency over time
- Rules: support rules that apply for some circumstances that affects\
  when running load tests:
  - 5XX status: add option for controlling how to handle these
  - 4XX status: add option for controlling how to handle these
  - 429 Too Many Requests: this should be respected by default
  - Option for controlling a specific status code
  - This could be set in its own section in the specfile
