# TODOs

- Rules: support rules that apply for some circumstances that affects\
  when running load tests:
  - 5XX status: add option for controlling how to handle these
  - 4XX status: add option for controlling how to handle these
  - 429 Too Many Requests: this should be respected by default
  - Option for controlling a specific status code
  - This could be set in its own section in the blastfile
- Re-work hooks:
  - [ ] One that is run per worker when starting: `on_start`
  - [ ] One that is run per worker when stopping: `on_stop`
- Add more capabilities to the Result module
  - Track number of requests per second
- Make it usable as a module that can be specified as a dependency
  - You might have to re-work the API it make it very clear
  - The documentation has to be very clear as well
