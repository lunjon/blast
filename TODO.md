# TODOs

- Print status to console during runtime
- Output results when exiting
- Define more hooks:
  - `post_request(Core.Response.t())`
    - Gets called after each request async
    - Requires that `Core.Response.t()` is defined\
      as only `Core.Request.t()` exists now
- Define rules: rules should apply for some circumstances that affects\
  when running load tests:
  - 5XX status: add option for controlling how to handle these
  - 4XX status: add option for controlling how to handle these
  - 429 Too Many Requests: this should be respected by default
