defmodule Blast.CLI.Parser do
  @methods ["GET", "POST", "PUT", "DELETE"]
  @method "GET"
  @duration 10_000
  @workers 1

  @errors %{invalid_url: {:error, "invalid URL"}}

  @help """
  blast - load test the APIs you love (or hate)!

  Required:
    -u/--url                  URL of the API to target.

  Options:
    -m/--method METHOD        HTTP method.
                              (string: default #{@method})
    -H/--header VALUE         HTTP header, can be specified multiple times.
                              Value should conform the format: "name: value"
                              (string)
    --data VALUE              Use as body string.
                              (string)
    --data-file FILEPATH      Read body from file.
                              (string)
    --data-form VALUE         URL encoded data, can be specied multiple times for each key/value pair.
                              Value should conform the format: "name: value"
                              (string)
    -w/--workers N            Number of concurrent workers to run.
                              (integer: default #{@workers})
    -f/--frequency N          Sets the frequency of requests per worker. To limit the total
                              request frequency use `--workers 1 --frequency N`.
                              A value of 0 means no limit.
                              (integer: default 0)
    --duration N              how many milliseconds to run
                              (integer: default #{@duration})
    --mode MODE               Starts a node in the given mode. Allowed values are
                              standalone, manager and worker for running a single node,
                              as manager node in distributed mode and worker node, respectively.
                              Distributed mode, i.e manager or worker, requires the --cookie flag.
                              If worker mode it also requires the --manager-node option.
                              (string: default standalone)
    --manager-address ADDR    Option required when running "--mode worker" for connecting to
                              the manager node as a worker. Value must be a reachable network address.
    -v/--verbose              Output logs.
                              (boolean: default false)
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
        mode: :string,
        manager_address: :string,
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
      with {:ok, mode_options} <-
             parse_mode(
               Keyword.get(args, :mode, "standalone"),
               Keyword.get(args, :manager_address)
             ),
           {:ok, url} <- Keyword.get(args, :url) |> parse_url(mode_options),
           {:ok, method} <- parse_method(Keyword.get(args, :method, @method)),
           {:ok, headers} <- parse_keyvalues(Keyword.take(args, [:header]), %{}),
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
          workers: Keyword.get(args, :workers, @workers),
          frequency: Keyword.get(args, :frequency, 0),
          duration: Keyword.get(args, :duration, @duration),
          distributed: Keyword.get(args, :distributed, false),
          connect: Keyword.get(args, :connect, ""),
          verbose: Keyword.get(args, :verbose, false),
          mode: mode_options
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

  defp parse_mode("standalone", _), do: {:ok, {:standalone, nil}}
  defp parse_mode("manager", _), do: {:ok, {:manager, nil}}

  defp parse_mode("worker", manager_addr) when not is_nil(manager_addr) do
    {:ok, {:worker, manager_addr}}
  end

  defp parse_mode(_mode, _manager_addr), do: {:error, "invalid --mode options"}

  defp parse_url(nil, {:worker, _}), do: {:ok, ""}

  defp parse_url(uri, _) when is_binary(uri) do
    uri
    |> URI.parse()
    |> parse_url(nil)
  end

  defp parse_url(%URI{scheme: scheme, host: host}, _)
       when is_nil(scheme) or is_nil(host) do
    @errors.invalid_url
  end

  defp parse_url(%URI{host: ""}, _), do: @errors.invalid_url

  defp parse_url(%URI{scheme: scheme} = uri, _)
       when scheme in ["http", "https"] do
    {:ok, to_string(uri)}
  end

  defp parse_url(_, _), do: @errors.invalid_url

  defp parse_method(method) do
    m = String.upcase(method)

    if m in @methods do
      {:ok, m}
    else
      {:error, "invalid method: #{method}"}
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
