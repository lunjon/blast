defmodule Blast.Main do
  alias Blast.CLI.Parser
  alias Core.Manager
  alias Core.Worker.Config
  require Logger

  def main(args) do
    Parser.parse_args(args)
    |> handle()
    |> run()

    Process.sleep(:infinity)
  end

  defp handle({:error, msg}) do
    IO.puts(:stderr, "error: #{msg}")
    System.halt(1)
  end

  defp handle({:help, msg}) do
    IO.puts(:stderr, msg)
    System.halt(1)
  end

  defp handle({:ok, args}) do
    if not args.verbose do
      Logger.configure(level: :none)
    else
      Logger.configure(level: :info)
    end

    Logger.debug("Args: #{inspect(args)}")

    request = %HTTPoison.Request{
      method: args.method,
      url: args.url,
      headers: args.headers,
      body: args.body
    }

    worker_config = %Config{
      frequency: args.frequency,
      request: request
    }

    {worker_config, args}
  end

  defp run({worker_config, args}) do
    Logger.info("Starting in mode: #{elem(args.mode, 0)}")

    kickoff =
      case args.mode do
        {:standalone, _} ->
          true

        {:manager, _} ->
          Manager.start_manager()
          true

        {:worker, manager_addr} ->
          Manager.start_worker(manager_addr)
          false
      end

    if kickoff do
      Manager.kickoff(worker_config, args.workers)
    end
  end
end
