# Spec

The _spec file_ defines which requests to send - and other settings.
It is written in YAML format which is easy to read and write.

The full spec looks like:
```yaml
# Required. Base URL of the API to target.
base-url: http://localhost:8080

# Optional: List of HTTP headers to add to all requests.
default-headers:
  - name: string # Required. Value of field.
    value: string # Required. Value of field.

# Required (cannot be empty). List of requests to send.
requests:
  - method: string # Optional (default: get). HTTP method of the request.
    path: string # Required: Relative path in URL to send to.
    headers: # Optional. List of HTTP headers.
      - name: string # Required. Value of field.
        value: string # Required. Value of field.
    # Only one of the following body fields can be specified
    body: string # Optional. Use as request body.
    body-file: string # Optional. Read request body from file.
    body-form: # Optional. List of name/value pairs to send as form.
      - name: string # Required. Name of field.
        value: string # Required. Value of field.
    # Optional. Integer >= 1 to make this request more likely to be sent.
    # For instance, a value of 2 means that it is twice as likely to be sent,
    # compared to values having weight 1.
    # Default is 1.
    weight: integer 

# Optional. Additional settings that configures the runtime.
settings:
  # Optional (integer >= 0). Frequency of requests (per worker).
  # Can be overriden from the command line options.
  # Default: 10. Zero (0) means unlimited frequency.
  frequency: 20
  # Optional. This option allows you to set how requests are started.
  # Read more about it below.
  control:       
    kind: rampup 
    # ...
```

## Settings

Additional settings can be specified in the `settings` section of the spec file.

### `control`

`control` is used to configure how workers are started and stoped. This allows
for different schemes that control how many workers, and thus requests, are sent
over time.

By default, i.e when omitting from `settings`, blast will start all workers and send at full capacity right from the start.
But if you like you could instead configure e.g a rampup, which increases requests over time.

The `control` object requires two fields:
- `kind (string)`: this sets the type of control to use
  - It currently only supports `rampup`
- `properties (object)`: the _properties_ are specific for each _kind_
  - See below what properties each kind supports

In other words, it looks something like:

```yaml
# NOTE! This exists under the root key `settings`.
control:
  kind: string
  properties:
    key: value
    # ...
```

#### Rampup

The _rampup_ control scheme has the following properties:
- `add (integer)`: how many workers to add on _every_ second
  - min: 1
  - max: 10
- `every (integer)`: how often to increase the workers in seconds
  - min: 5
  - max: 300
- `start (integer)`: how many workers to start with
  - default: 1
  - min: 1
  - max: 100
- `target (integer)`: the target number of workers to reach
  - min: 5
  - max: 10000

Example:
```yaml
control:
  kind: rampup
  properties:
    start: 10
    add: 2
    every: 10
    target: 100
```

This rampup schemes reads: starting with 10 workers, add 2 workers every 10 seconds until we
reach 100 workers.

## Example
Below shows a full example of a spec file.

```yaml
base-url: https://example.api.com

default-headers:
  - name: "api-key"
    value: "blast-4-life"

requests:
  - method: get
    path: /dogs
  - method: post
    path: /cats
    body-file: "local.file.json"
    headers:
      - name: content-type
        name: application/json

settings:
  frequency: 0 # 0 == no limit -> blast away
  control:
    kind: rampup
    properties:
      add: 1
      every: 10
      start: 2
      target: 500
```
