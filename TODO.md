# TODOs

- Define rules: rules should apply for some circumstances that affects\
  when running load tests:
  - 5XX status: add option for controlling how to handle these
  - 4XX status: add option for controlling how to handle these
  - 429 Too Many Requests: this should be respected by default
- Re-work hooks:
  - Define clear lifecycle hooks:
    - One that is run ONCE (not for each worker) before it all begins. This should also return the context passed to other hooks.\
      Perhaps `init` could be this hook.
    - One that is run ONCE on stop. This could be called `stop`.
    - Keep `pre_request` as is, or rename to something better.
- Spec: add `weight` to a request meaning that it is more likely (if weight is higher compared to others) to be sent
  - For instance: a weight of 2 means that it is twice as likely to be choosen
- Make it usable as a module that can be specified as a dependency
  - You might have to re-work the API it make it very clear
  - The documentation has to be very clear as well
- Add documentation on design and how modules interact with each other
