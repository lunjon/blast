defmodule Blast.CLI do
  require Logger

  @timeout 10_000
  @worker_count 1

  @help """
  blast - load test the APIs you love (or hate)!

  Required:
    --url   the URL to the API to target


  Options:
    -w/--workers   number of concurrent workers to run
                (integer: default 1)
    --timeout   how many milliseconds to run
                (integer: default l0000)
    -v/--verbose   output logs
                (boolean: default false)
    --help      display this help message
  """

  def main([]) do
    IO.warn("Missing required parameter: --url")
    System.halt(1)
  end

  def main(args) do
    OptionParser.parse(args,
      strict: [
        url: :string,
        workers: :integer,
        timeout: :integer,
        verbose: :boolean,
        help: :boolean
      ],
      aliases: [
        u: :url,
        w: :workers,
        v: :verbose,
        h: :help
      ]
    )
    |> parse_args()
  end

  def parse_args({args, [], []}) do
    if not Keyword.get(args, :verbose, false) do
      Logger.configure(level: :none)
    end

    Logger.debug("Args: #{inspect(args)}")

    if Keyword.get(args, :help) do
      IO.puts(@help)
      System.stop(1)
    else
      url = Keyword.get(args, :url)
      workers = Keyword.get(args, :workers, @worker_count)
      timeout = Keyword.get(args, :timeout, @timeout)

      run(workers, timeout, url)
    end
  end

  def parse_args({_, _rest_args, _invalid_args}) do
    IO.warn("unknown and/or invalid arguments")
    System.stop(1)
  end

  defp run(worker_count, timeout, url) do
    children = [
      Blast.Results,
      Blast.WorkerSupervisor,
      {Blast.Gatherer, {url, worker_count, self()}}
    ]

    opts = [strategy: :one_for_all, name: Blast.Supervisor]
    Supervisor.start_link(children, opts)

    receive do
      {:done} ->
        Logger.info("Received done")
    after
      timeout ->
        Logger.info("Stopping workers...")
        Blast.WorkerSupervisor.stop_workers()
    end

    IO.puts("Results: #{inspect(Blast.Results.get())}")
  end
end
