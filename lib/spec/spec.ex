defmodule Blast.Spec do
  @moduledoc """
  A blast file defines what the load tests should target.
  It is loaded from a YAML file (or string) and consists
  of at least on root element that defines the endpoints
  to target in the requests.
  """

  alias __MODULE__
  alias Blast.Request

  @type t :: %{
    base_url: binary(),
    requests: [Request.t()],
    default_headers: [{binary(), binary()}],
  }

  @enforce_keys [:base_url, :requests]
  defstruct [base_url: "", requests: "", default_headers: []]

  @doc """
  Loads a spec from a `filepath`.
  The file must be a file in the YAML format.
  """
  def load_file(filepath) do
    case File.read(filepath) do
      {:ok, data} -> load_string(data)
      err -> err
    end
  end

  @doc """
  Loads a spec (`blastfile`) from a string in YAML format.
  See documentation for full specification.
  """
  @spec load_string(binary()) :: {:ok, t()} | {:error, binary()}
  def load_string(string) when is_binary(string) do
    with {:ok, yaml} <- YamlElixir.read_from_string(string),
         {:ok, base_url} <- get_required("base-url", yaml["base-url"]),
         {:ok, default_headers} <- parse_headers(yaml["default-headers"]),
         {:ok, requests} <- parse_requests(default_headers, base_url, yaml["requests"]) do
        requests = Enum.flat_map(requests, & &1)
        spec = %Blast.Spec{
          base_url: base_url,
          requests: requests,
          default_headers: default_headers
        }

        {:ok, spec}
    else
      err -> err
    end
  end

  @doc """
  Parse the spec and build a list of requests from it.
  """
  @spec get_requests(t()) :: [Request.t()]
  def get_requests(%Spec{requests: requests} = _spec) do
    requests
    |> Enum.shuffle()
  end

  defp parse_requests(_, _, nil), do: {:error, "missing required field: requests"}
  defp parse_requests(_, _, []), do: {:error, "requests must not be empty"}

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

  defp get_required(field, nil), do: {:error, "missing required field in root: #{field}"}

  defp get_required(_field, value), do: {:ok, value}

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

  defp parse_body_fields(_, _, _) do
    { :error, "invalid combination of body fields: request may optionally contain one of body, body-file or body-form" }
  end
end
