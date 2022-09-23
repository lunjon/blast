defmodule Blast.Main do
  alias Blast.CLI.Parser
  alias Core.WorkerConfig
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

    worker_config = %WorkerConfig{
      frequency: args.frequency,
      request: request
    }

    {worker_config, args}
  end

  defp run({worker_config, args}) do
    kickoff =
      case args.mode do
        {:standalone, _} ->
          Logger.info("Starting standalone mode with #{args.workers} worker(s)")
          true

        {:manager, _} ->
          Core.Manager.start_manager()
          true

        {:worker, manager_addr} ->
          Core.Manager.start_worker(manager_addr)
          false
      end

    if kickoff do
      Core.Manager.kickoff(worker_config, args.workers)
    end
  end
end
