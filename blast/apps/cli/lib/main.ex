defmodule Blast.Main do
  alias Blast.CLI.Parser
  alias Core.WorkerConfig
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

    request = %HTTPoison.Request{
      method: args.method,
      url: args.url,
      headers: args.headers,
      body: args.body
    }

    worker_config = %WorkerConfig{
      frequency: args.frequency
    }

    run({request, worker_config}, args)
  end

  defp run(worker_config, args) do
    Application.start(:core)
    Core.Manager.kickoff(worker_config, args.workers)
    Process.sleep(:infinity)
  end
end
