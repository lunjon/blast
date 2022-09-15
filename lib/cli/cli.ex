defmodule Blast.CLI do
  alias Blast.CLI.ArgParser
  require Logger

  def main(args) do
    ArgParser.parse(args)
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
    run(args.url, args.timeout, args.workers)
  end

  defp run(url, timeout, workers) do
    children = [
      Blast.Results,
      Blast.WorkerSupervisor,
      {Blast.Gatherer, {url, workers, self()}}
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
