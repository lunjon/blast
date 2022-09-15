defmodule Blast.CLI.ArgParser do
  @method "GET"
  @timeout 10_000
  @worker_count 1

  @help """
  blast - load test the APIs you love (or hate)!

  Required:
    -u/--url       the URL to the API to target

  Options:
    -m/--method    HTTP method
                   (string: default #{@method})
    -w/--workers   number of concurrent workers to run
                   (integer: default #{@worker_count})
    --timeout      how many milliseconds to run
                   (integer: default #{@timeout})
    -v/--verbose   output logs
                   (boolean: default false)
    --help         display this help message
  """

  def parse([]) do
    {:error, "Missing required parameter: --url"}
  end

  def parse(args) do
    OptionParser.parse(args,
      strict: [
        url: :string,
        method: :string,
        workers: :integer,
        timeout: :integer,
        verbose: :boolean,
        help: :boolean
      ],
      aliases: [
        m: :method,
        u: :url,
        w: :workers,
        v: :verbose,
        h: :help
      ]
    )
    |> parse_args()
  end

  defp parse_args({args, [], []}) do
    verbose = Keyword.get(args, :verbose, false)

    if not verbose do
      Logger.configure(level: :none)
    end

    if Keyword.get(args, :help) do
      {:help, @help}
    else
      args = %{
        url: Keyword.get(args, :url),
        method: Keyword.get(args, :url, @method),
        workers: Keyword.get(args, :workers, @worker_count),
        timeout: Keyword.get(args, :timeout, @timeout),
        verbose: verbose
      }

      {:ok, args}
    end
  end

  defp parse_args({_, _rest_args, _invalid_args}) do
    {:error, "unknown and/or invalid arguments"}
  end
end
