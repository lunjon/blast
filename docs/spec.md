# Spec

The specfile defines the requests to send.
The full spec looks like:

```yaml
endpoints: # Required (cannot be empty). List of endpoints.
  - base-url: http://localhost # Required. Base URL of this endpoint.
    default-headers: # Optional: List of HTTP headers to add to all requests.
      - name: string # Required. Value of field.
        value: string # Required. Value of field.
    requests: # Required (cannot be empty). List of requests to send.
      - method: get # Optional (default: get). HTTP method of the request.
        path: /path # Required: Relative path in URL to send to.
        headers: # Optional. List of HTTP headers.
          - name: string # Required. Value of field.
            value: string # Required. Value of field.
        # Only one of the following (optional) body* fields can be specified
        body: string # Optional. Use as request body.
        body-file: string # Optional. Read request body from file.
        body-form: # Optional. List of name/value pairs to send as form.
          - name: string # Required. Name of field.
            value: string # Required. Value of field.
```
