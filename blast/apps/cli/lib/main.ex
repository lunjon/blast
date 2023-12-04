defmodule Blast.Main do
  alias Blast.CLI.Parser
  alias Core.Manager
  alias Core.Request
  alias Core.Worker.Config
  require Logger

  def main(args) do
    Parser.parse_args(args)
    |> handle()
    |> Manager.kickoff()

    Process.sleep(:infinity)
  end

  defp handle({:error, msg}) do
    IO.puts(:stderr, "error: #{msg}")
    System.stop(1)
    Process.sleep(:infinity)
  end

  defp handle({:help, msg}) do
    IO.puts(:stderr, msg)
    System.stop(1)
    Process.sleep(:infinity)
  end

  defp handle({:ok, args}) do
    if not args.verbose do
      Logger.configure(level: :error)
    else
      Logger.configure(level: :info)
    end

    Logger.debug("Args: #{inspect(args)}")

    request = %Request{
      method: args.method,
      url: args.url,
      headers: args.headers,
      body: args.body
    }

    %Config{
      workers: args.workers,
      frequency: args.frequency,
      request: request
    }
    |> load_hooks(args.hook_file)
  end

  defp load_hooks(config, nil), do: config

  defp load_hooks(config, filepath) do
    [{module, _}] = Code.require_file(filepath)

    case Kernel.function_exported?(module, :pre_request, 1) do
      true ->
        Config.set_pre_request_hook(config, fn req ->
          apply(module, :pre_request, [req])
        end)

      false ->
        config
    end
  end
end
