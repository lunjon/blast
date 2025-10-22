defmodule Blast.CLI.Parser do
  @workers 2
  @frequency 10

  @help """
  blast - load test HTTP APIs

  Options:
    -b/--blastfile FILE  File path to blast file.
                         (default: looks for blast.{ex,exs} in current working directory)
    -w/--workers N       Number of concurrent workers to run. This option is only viable
                         when no control has been configured in the settings in the spec.
                         (default: #{@workers})
    -f/--frequency N     Sets the rate of requests per worker. 
                         This will override any value configured in the settings in the spec.
                         A value of 0 means no limit. (default: #{@frequency})
    --log LEVEL          Configure log level (default: warn, allowed: debug, info, warn, error)
    --headless           Do not start web interface and start blasting right away.
    --generate BASE_URL  Generate an example blastfile with the given base URL.
                         and writes it to stdout.
    --help               Display this help message.
  """

  def parse_args(args) do
    OptionParser.parse(args,
      strict: [
        blastfile: :string,
        workers: :integer,
        frequency: :integer,
        duration: :integer,
        log: :string,
        headless: :boolean,
        generate: :string,
        help: :boolean
      ],
      aliases: [
        b: :blastfile,
        w: :workers,
        f: :frequency,
        h: :help
      ]
    )
    |> handle_parsed_args()
  end

  defp handle_parsed_args({args, [], []}) do
    if Keyword.get(args, :help) do
      {:help, @help}
    else
      with {:ok, level} <- get_log_level(args) do
        args = %{
          blastfile: Keyword.get(args, :blastfile),
          workers: Keyword.get(args, :workers, @workers),
          frequency: Keyword.get(args, :frequency, @frequency),
          log: level,
          headless: Keyword.get(args, :headless, false),
          generate: Keyword.get(args, :generate)
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

  defp get_log_level(args) do
    case Keyword.get(args, :log) do
      nil ->
        {:ok, :warn}

      level ->
        case String.downcase(level) do
          "debug" -> {:ok, :debug}
          "info" -> {:ok, :info}
          "warn" -> {:ok, :warning}
          "error" -> {:ok, :error}
          _ -> {:error, "invalid log level: #{level}"}
        end
    end
  end
end
