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

    # Process.sleep(:infinity)
    Blast.CLI.REPL.start()
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

    hooks = load_hooks(args.hook_file)

    %Config{
      workers: args.workers,
      frequency: args.frequency,
      request: request,
      hooks: hooks
    }
  end

  defp load_hooks(nil), do: %{}

  defp load_hooks(filepath) do
    [{module, _}] = Code.require_file(filepath)

    hooks =
      case Kernel.function_exported?(module, :init, 0) do
        true ->
          {:ok, cx} = apply(module, :init, [])
          %{cx: cx}

        false ->
          %{cx: %{}}
      end

    case Kernel.function_exported?(module, :pre_request, 2) do
      true ->
        Map.put(hooks, :pre_request, fn cx, req ->
          apply(module, :pre_request, [cx, req])
        end)

      false ->
        hooks
    end
  end
end
