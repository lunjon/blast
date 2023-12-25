# TODOs

- Rules: support rules that apply for some circumstances that affects\
  when running load tests:
  - 5XX status: add option for controlling how to handle these
  - 4XX status: add option for controlling how to handle these
  - 429 Too Many Requests: this should be respected by default
  - Option for controlling a specific status code
  - This could be set in its own section in the blastfile
- Re-work hooks:
  - Define clear lifecycle hooks:
    - [ ] One that is run ONCE (not for each worker) before it all begins.\
      This should also return the context passed to other hooks.\
      `init` should be this hook.
    - [ ] One that is run per worker when starting: `on_start`
    - [ ] One that is run per worker when stopping: `on_stop`
    - [ ] Rename `pre_request` to `on_request`
- Add more capabilities to the Result module
  - Track number of requests per second
- Make it usable as a module that can be specified as a dependency
  - You might have to re-work the API it make it very clear
  - The documentation has to be very clear as well
- Add documentation on design and how modules interact with each other
