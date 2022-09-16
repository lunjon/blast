defmodule Blast.CLI do
  alias Blast.CLI.Parser
  require Logger

  def main(args) do
    Parser.parse_args(args)
    |> handle()
  end

  defp handle({:error, msg}) do
    IO.puts("error: #{msg}")
    System.stop(1)
  end

  defp handle({:help, msg}) do
    IO.puts(msg)
    System.stop(1)
  end

  defp handle({:ok, args}) do
    if not args.verbose do
      Logger.configure(level: :none)
    else
      Logger.configure(level: :info)
    end

    Logger.debug("Args: #{inspect(args)}")

    req = %HTTPoison.Request{
      method: args.method,
      url: args.url,
      headers: args.headers
    }

    run(req, args.timeout, args.workers)
  end

  defp run(req, timeout, workers) do
    children = [
      Blast.Results,
      Blast.WorkerSupervisor,
      {Blast.Gatherer, {req, workers, self()}}
    ]

    Logger.info("Starting #{workers} worker(s)")
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

    Logger.flush()
    IO.puts("Results: #{inspect(Blast.Results.get())}")
  end
end
