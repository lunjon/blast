# Spec

The specfile defines the requests to send.
The full spec looks like:

```yaml
endpoints: # Required (cannot be empty). List of endpoints.
  - base-url: http://localhost # Required. Base URL of this endpoint.
    default-headers: # Optional: List of HTTP headers to add to all requests.
      - name: string # Required.
        value: string # Required.
    requests: # Required (cannot be empty). List of requests to send.
      - method: get # Optional (default: get). HTTP method of the request.
        path: /path # Required: Relative path in URL to send to.
        headers: # Optional. List of HTTP headers.
          - name: string # Required.
            value: string # Required.
```
