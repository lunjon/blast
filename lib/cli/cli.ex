defmodule Blast.CLI do
  alias Blast.CLI.Parser
  require Logger

  def main(args) do
    try do
      Parser.parse_args(args)
      |> handle()
    rescue
      e ->
        msg = Exception.format(:error, e)
        Logger.error(msg)
        IO.puts(:stderr, msg)
        System.stop(1)
    end
  end

  defp handle({:error, msg}) do
    IO.puts(:stderr, "error: #{msg}")
    System.stop(1)
  end

  defp handle({:help, msg}) do
    IO.puts(:stderr, msg)
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
      headers: args.headers,
      body: args.body
    }

    run(req, args)
  end

  defp run(req, args) do
    children = [
      Blast.Results,
      Blast.WorkerSupervisor,
      {Blast.Manager, {req, args.workers, self()}}
    ]

    opts = [strategy: :one_for_all, name: Blast.Supervisor]
    Supervisor.start_link(children, opts)

    receive do
      {:done} ->
        Logger.info("Received done")
    after
      args.duration ->
        Logger.info("Stopping workers...")
        Blast.Manager.stop_all()
    end

    Blast.Results.get()
    |> Blast.Format.format_result(:json)
    |> IO.puts()
  end
end
