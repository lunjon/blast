defmodule Blast.Spec do
  @moduledoc """
  A spec defines what the load tests should target, such as
  base URL and other options.

  The blast spec is loaded from a standalone Elixir module
  specified in a file by the user.
  """

  alias Blast.Spec.Settings
  alias Blast.Request

  @type t :: %__MODULE__{
          settings: nil | Settings.t(),
          base_url: binary(),
          requests: [Request.t()]
        }

  @enforce_keys [:base_url, :requests]
  defstruct settings: nil,
            base_url: "",
            requests: []

  @doc """
  Loads a spec from the Elixir module by invoking the expected functions.
  See documentation for full specification.
  """
  @spec load(module()) :: {:ok, t()} | {:error, binary()}
  def load(module) do
    with {:ok, base_url} <- load_base_url(module),
         {:ok, default_headers} <- load_default_headers(module),
         {:ok, settings} <- load_settings(module),
         {:ok, requests} <- load_requests(module, base_url, default_headers) do
      requests = Enum.flat_map(requests, & &1)

      spec = %Blast.Spec{
        base_url: base_url,
        requests: Enum.shuffle(requests),
        settings: settings
      }

      {:ok, spec}
    else
      err -> err
    end
  end

  defp load_base_url(module) do
    if Kernel.function_exported?(module, :base_url, 0) do
      case apply(module, :base_url, []) do
        url when is_binary(url) -> {:ok, url}
        res -> {:error, "unrecognizable return from base_url: #{inspect(res)}"}
      end
    else
      {:error, "module missing required function: base_url"}
    end
  end

  defp load_default_headers(module) do
    if Kernel.function_exported?(module, :default_headers, 0) do
      res = apply(module, :default_headers, [])
      parse_headers(res)
    else
      {:ok, []}
    end
  end

  defp load_requests(module, base_url, default_headers) do
    if Kernel.function_exported?(module, :requests, 0) do
      res = apply(module, :requests, [])
      parse_requests(base_url, default_headers, res)
    else
      {:error, "module missing required function: requests"}
    end
  end

  defp load_settings(module) do
    if Kernel.function_exported?(module, :settings, 0) do
      apply(module, :settings, []) |> Settings.parse()
    else
      {:ok, %Settings{}}
    end
  end

  defp parse_requests(_, _, []), do: {:error, "requests must not be empty"}

  defp parse_requests(base_url, default_headers, requests) when is_list(requests) do
    requests
    |> Enum.map(&parse_request(&1, base_url, default_headers))
    |> find_error()
  end

  defp parse_requests(_, _, _), do: {:error, "requests() returned invalid or unexpected data"}

  defp parse_request(request, base_url, default_headers) do
    with :ok <- check_request_attributes(request),
         {:ok, path} <- get_required("request", :path, request[:path]),
         {:ok, method} <- get_method(request[:method]),
         {:ok, headers} <- parse_headers(request[:headers]),
         {:ok, body} <-
           parse_body_fields(request[:body], request[:body_file], request[:body_form]) do
      headers = (headers ++ default_headers) |> Enum.dedup()
      weight = Map.get(request, :weight, 1)

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
  end

  @request_attributes [:method, :path, :headers, :body, :body_file, :body_form]
  defp check_request_attributes(request) do
    invalid_keys =
      Map.keys(request)
      |> Enum.filter(fn attr -> attr not in @request_attributes end)

    case invalid_keys do
      [] ->
        :ok

      attribs ->
        msg = Enum.join(attribs, ", ")
        {:error, "invalid attributes in request: #{msg}"}
    end
  end

  defp parse_headers(nil), do: {:ok, []}

  defp parse_headers(headers) when is_list(headers) do
    headers
    |> Enum.map(&parse_header/1)
    |> find_error()
  end

  defp parse_header({name, value}), do: {:ok, {name, value}}

  defp parse_header(header) do
    {:error,
     "unexpected header format - expected a {name, value} tuple but was: #{inspect(header)}"}
  end

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

  defp get_method(method) when is_atom(method) do
    to_string(method) |> get_method()
  end

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
    {:error,
     "invalid combination of body fields: request may optionally contain one of body, body_file or body_form"}
  end
end
