defmodule Blast.CLI.Parser do
  @methods ["GET", "POST", "PUT", "DELETE"]
  @method "GET"
  @timeout 10_000
  @workers 1

  @help """
  blast - load test the APIs you love (or hate)!

  Required:
    -u/--url              the URL to the API to target

  Options:
    -m/--method METHOD    HTTP method
                          (string: default #{@method})
    -H/--header VALUE     HTTP header, can be specified multiple times.
                          Value should conform the format: "Name: value"
                          (string)
    -w/--workers N        number of concurrent workers to run
                          (integer: default #{@workers})
    --timeout N           how many milliseconds to run
                          (integer: default #{@timeout})
    -v/--verbose          output logs
                          (boolean: default false)
    --help                display this help message
  """

  def parse_args([]) do
    {:error, "Missing required parameter: --url"}
  end

  def parse_args(args) do
    OptionParser.parse(args,
      strict: [
        url: :string,
        method: :string,
        header: [:string, :keep],
        workers: :integer,
        timeout: :integer,
        verbose: :boolean,
        help: :boolean
      ],
      aliases: [
        m: :method,
        u: :url,
        H: :header,
        w: :workers,
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
      with {:ok, headers} <- parse_headers(Keyword.take(args, [:header]), %{}),
           {:ok, method} <- parse_method(Keyword.get(args, :method, @method)) do
        args = %{
          url: Keyword.get(args, :url),
          method: method,
          headers: headers,
          workers: Keyword.get(args, :workers, @workers),
          timeout: Keyword.get(args, :timeout, @timeout),
          verbose: Keyword.get(args, :verbose, false)
        }

        {:ok, args}
      else
        err -> err
      end
    end
  end

  defp handle_parsed_args({_, _rest_args, _invalid_args}) do
    {:error, "unknown and/or invalid arguments"}
  end

  defp parse_method(method) do
    m = String.upcase(method)

    if m in @methods do
      {:ok, m}
    else
      {:error, "invalid method: #{method}"}
    end
  end

  defp parse_headers([], headers), do: {:ok, headers}

  defp parse_headers([head | tail], headers) do
    {_, header} = head

    case parse_header(header) do
      {:error, _msg} = err ->
        err

      {:ok, name, value} ->
        {_, hs} =
          Map.get_and_update(headers, name, fn
            nil -> {value, value}
            current -> {value, "#{current}; #{value}"}
          end)

        parse_headers(tail, hs)
    end
  end

  @header_regex ~r/^([a-zA-Z][a-zA-Z-]*[a-zA-Z]?):\s?(.+)$/
  def parse_header(header) when is_binary(header) do
    Regex.run(@header_regex, header)
    |> handle_header_match()
  end

  defp handle_header_match([_header, name, value]) do
    {:ok, name, value}
  end

  defp handle_header_match(nil) do
    {:error, "no match"}
  end
end
