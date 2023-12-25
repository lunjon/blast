defmodule Blast.Spec do
  @moduledoc """
  A blast spec defines what the load tests should target.
  It is loaded from a YAML file (or string) and consists
  of at least on root element that defines the endpoints
  to target in the requests.

  An `endpoint` defines a base URL along with requests
  to send to this endpoint.

  ```yaml
  endpoints: # Required (cannot be empty).
    - base-url: string # Base URL of the endpoint, e.g. https://example.com
      requests: # Required (cannot be empty). List of requests to send.
        - method: get # HTTP method. Defaults to `get` if omitted.
          path: "/some/path" # Required. Relate URL path.
  ```
  """

  alias __MODULE__
  alias Blast.Spec.Endpoint
  alias Blast.Request

  @type t :: %{endpoints: [Endpoint.t()]}

  @enforce_keys [:endpoints]
  defstruct endpoints: [], default: %{}

  def load_file(filepath) do
    case File.read(filepath) do
      {:ok, data} -> load_string(data)
      err -> err
    end
  end

  def load_string(string) when is_binary(string) do
    with {:ok, yaml} <- YamlElixir.read_from_string(string),
         {:ok, endpoints} <- parse_endpoints(yaml["endpoints"]) do
      {:ok,
       %Blast.Spec{
         endpoints: endpoints
       }}
    else
      err -> err
    end
  end

  @doc """
  Parse the spec and build a list of requests from it.
  """
  @spec get_requests(t()) :: [Request.t()]
  def get_requests(%Spec{endpoints: endpoints}) do
    endpoints
    |> Enum.flat_map(fn endpoint ->
      endpoint.requests
    end)
    |> Enum.shuffle()
  end

  defp parse_endpoints(nil), do: {:error, "missing required field: endpoints"}
  defp parse_endpoints([]), do: {:error, "endpoints must not be empty"}

  defp parse_endpoints(endpoints) when is_list(endpoints) do
    endpoints
    |> Enum.map(fn endpoint ->
      with {:ok, base_url} <- get_required("endpoints", "base-url", endpoint["base-url"]),
           {:ok, default_headers} <- parse_headers(endpoint["default-headers"]),
           {:ok, requests} <- parse_requests(default_headers, base_url, endpoint["requests"]) do
        requests = Enum.flat_map(requests, & &1)
        {:ok, %Endpoint{base_url: base_url, requests: requests}}
      else
        err -> err
      end
    end)
    |> find_error()
  end

  defp parse_endpoints(_), do: {:error, "invalid type for endpoints"}

  defp parse_requests(_, _, nil), do: {:error, "missing required field in endpoint: requests"}
  defp parse_requests(_, _, []), do: {:error, "endpoint requests must not be empty"}

  defp parse_requests(default_headers, base_url, requests) when is_list(requests) do
    requests
    |> Enum.map(fn request ->
      with {:ok, path} <- get_required("request", "path", request["path"]),
           {:ok, headers} <- parse_headers(request["headers"]),
           {:ok, body} <-
             parse_body_fields(request["body"], request["body-file"], request["body-form"]),
           {:ok, method} <- get_method(request["method"]) do
        headers = (headers ++ default_headers) |> Enum.dedup()

        weight = Map.get(request, "weight", 1)

        req = %Request{
          url: URI.parse(base_url) |> URI.append_path(path) |> URI.to_string(),
          method: String.to_atom(method),
          headers: Map.new(headers),
          body: body
        }

        {:ok, Enum.map(1..weight, fn _ -> req end)}
      else
        err -> err
      end
    end)
    |> find_error()
  end

  defp parse_requests(_, _, _), do: {:error, "invalid type for endpoint requests"}

  defp parse_headers(nil), do: {:ok, []}

  defp parse_headers(headers) when is_list(headers) do
    headers
    |> Enum.map(&parse_header/1)
    |> find_error()
  end

  defp parse_header(%{"name" => name, "value" => value}), do: {:ok, {name, value}}
  defp parse_header(data), do: {:error, "unexpected fields: #{inspect(data)}"}

  defp get_required(root, field, nil), do: {:error, "missing required field in #{root}: #{field}"}
  defp get_required(_, _field, value), do: {:ok, value}

  defp find_error(results) do
    err =
      Enum.find(results, fn res ->
        case res do
          {:error, _} -> true
          _ -> false
        end
      end)

    case err do
      nil -> {:ok, Enum.map(results, &elem(&1, 1))}
      _ -> err
    end
  end

  @methods ["get", "post", "put", "delete", "options"]
  defp get_method(nil), do: {:ok, "get"}

  defp get_method(method) do
    method = String.downcase(method)

    if method in @methods do
      {:ok, method}
    else
      {:error, "unsupported or invalid method: #{method}"}
    end
  end

  defp parse_body_fields(nil, nil, nil), do: {:ok, ""}

  defp parse_body_fields(body, nil, nil) when is_binary(body), do: {:ok, body}

  defp parse_body_fields(nil, body_file, nil) do
    case File.read(body_file) do
      {:ok, body} -> {:ok, body}
      {:error, reason} -> "error reading file #{body_file}: #{inspect(reason)}"
    end
  end

  defp parse_body_fields(nil, nil, body_form) when is_list(body_form) do
    parse_headers(body_form)
  end

  defp parse_body_fields(_, _, _),
    do:
      {:error,
       "invalid combination of body fields: request may optionally contain one of body, body-file or body-form"}
end
