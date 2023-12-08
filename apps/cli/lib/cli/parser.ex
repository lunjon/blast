defmodule Blast.CLI.Parser do
  @methods [:get, :post, :put, :delete]
  @method :get
  @duration 10_000
  @workers 1

  @errors %{invalid_url: {:error, "invalid URL"}}

  @help """
  blast - load testing of HTTP APIs

  Required:
    -u/--url                  URL of the API to target.

  Options:
    -m/--method METHOD        HTTP method.
                              (default: #{to_string(@method)})
    -H/--header VALUE         HTTP header, can be specified multiple times.
                              Value should conform the format: "name: value"
    --data VALUE              Use as body string.
    --data-file FILEPATH      Read body from file.
    --data-form VALUE         URL encoded data, can be specied multiple times for each key/value pair.
                              Value should conform the format: "name: value".
    -w/--workers N            Number of concurrent workers to run.
                              (default: #{@workers})
    -f/--frequency N          Sets the frequency of requests per worker. To limit the total
                              request frequency use `--workers 1 --frequency N`.
                              A value of 0 means no limit. (default: 0)
    --duration N              How many milliseconds to run.
                              (default: #{@duration})
    --hooks FILE              Load an elixir file (.ex) as hooks module.
    -v/--verbose              Output logs. (default: false)
    --help                    Display this help message.
  """

  def parse_args([]) do
    msg = """
    error: missing required parameter: --url

    #{@help}
    """

    {:error, msg}
  end

  def parse_args(args) do
    OptionParser.parse(args,
      strict: [
        url: :string,
        method: :string,
        header: [:string, :keep],
        workers: :integer,
        frequency: :integer,
        duration: :integer,
        verbose: :boolean,
        data: :string,
        data_file: :string,
        data_form: [:string, :keep],
        hooks: :string,
        help: :boolean
      ],
      aliases: [
        m: :method,
        u: :url,
        H: :header,
        w: :workers,
        f: :frequency,
        v: :verbose,
        h: :help
      ]
    )
    |> handle_parsed_args()
  end

  defp handle_parsed_args({args, [], []}) do
    if Keyword.get(args, :help) do
      {:help, @help}
    else
      with {:ok, url} <- Keyword.get(args, :url) |> parse_url(),
           {:ok, method} <- parse_method(Keyword.get(args, :method, @method)),
           {:ok, headers} <- parse_keyvalues(Keyword.take(args, [:header]), %{}),
           {:ok, hook_file} <- parse_hook_file(Keyword.get(args, :hooks)),
           {:ok, data} <-
             parse_data_flags(
               Keyword.get(args, :data),
               Keyword.get(args, :data_file),
               Keyword.take(args, [:data_form])
             ) do
        args = %{
          url: url,
          method: method,
          headers: headers,
          body: data,
          hook_file: hook_file,
          workers: Keyword.get(args, :workers, @workers),
          frequency: Keyword.get(args, :frequency, 0),
          duration: Keyword.get(args, :duration, @duration),
          verbose: Keyword.get(args, :verbose, false)
        }

        {:ok, args}
      else
        err -> err
      end
    end
  end

  defp handle_parsed_args({_, _rest_args, invalid_args}) do
    invalid =
      invalid_args
      |> Enum.map(fn {arg, _} -> arg end)
      |> Enum.join(", ")

    {:error, "invalid arguments: #{invalid}"}
  end

  defp parse_url(nil), do: {:error, "missing url"}

  defp parse_url(uri) when is_binary(uri) do
    uri
    |> URI.parse()
    |> parse_uri()
  end

  defp parse_uri(%URI{scheme: scheme, host: host})
       when is_nil(scheme) or is_nil(host) do
    @errors.invalid_url
  end

  defp parse_uri(%URI{host: ""}), do: @errors.invalid_url

  defp parse_uri(%URI{scheme: scheme} = uri)
       when scheme in ["http", "https"] do
    {:ok, to_string(uri)}
  end

  defp parse_uri(%URI{scheme: scheme}) do
    {:error, "unsupported scheme: #{scheme}"}
  end

  defp parse_method(@method), do: {:ok, @method}

  defp parse_method(method) do
    m = String.downcase(method) |> String.to_atom()

    if m in @methods do
      {:ok, m}
    else
      {:error, "invalid method: #{method}"}
    end
  end

  defp parse_hook_file(nil), do: {:ok, nil}

  defp parse_hook_file(filepath) do
    case File.exists?(filepath) do
      false -> {:error, "file not found: #{filepath}"}
      true -> {:ok, filepath}
    end
  end

  defdelegate parse_keyvalues(list, map), to: Blast.CLI.HeaderParser

  defdelegate parse_keyvalue(value), to: Blast.CLI.HeaderParser

  # --data* flag parsing

  defp parse_data_flags(nil, nil, []), do: {:ok, ""}

  defp parse_data_flags(data, nil, []), do: {:ok, data}

  defp parse_data_flags(nil, data_file, []) do
    if File.exists?(data_file) do
      {:ok, {:file, data_file}}
    else
      {:error, "file not found: #{data_file}"}
    end
  end

  defp parse_data_flags(nil, nil, data_form) do
    case parse_keyvalues(data_form, %{}) do
      {:ok, map} ->
        form = Enum.map(map, fn {key, value} -> {key, value} end)
        {:ok, {:form, form}}

      err ->
        err
    end
  end

  defp parse_data_flags(_, _, _), do: {:error, "invalid combination of data flags"}
end
