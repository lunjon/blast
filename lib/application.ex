defmodule Blast.Application do
  use Application
  alias Blast.CLI.{Parser, Output}
  alias Blast.Worker.Config
  require Logger

  @impl true
  def start(_type, _args) do
    config = Parser.parse_args([])
      |> handle()

    opts = [strategy: :one_for_one, name: Blast.Supervisor]

    System.get_env("MIX_ENV", nil)
    |> children(config)
    |> Supervisor.start_link(opts)
  end

  defp handle({:error, msg}) do
    Output.error(msg)
    abort()
  end

  defp handle({:help, msg}) do
    IO.puts(:stderr, msg)
    abort()
  end

  defp handle({:ok, args}) do
    if not args.verbose do
      Logger.configure(level: :error)
    else
      Logger.configure(level: :info)
    end

    Logger.debug("Args: #{inspect(args)}")

    requests = Blast.Spec.get_requests(args.spec)

    hooks = load_hooks(args.hook_file)

     %Config{
       workers: args.workers,
       frequency: args.frequency,
       requests: requests,
       hooks: hooks
     }
  end

  defp load_hooks(nil), do: %{}

  defp load_hooks(filepath) do
    [{module, _}] = Code.require_file(filepath)

    hooks =
      case Kernel.function_exported?(module, :init, 0) do
        true ->
          cx = apply(module, :init, []) |> get_context()
          %{cx: cx}

        false ->
          %{cx: %{}}
      end

    case Kernel.function_exported?(module, :on_request, 2) do
      true ->
        Map.put(hooks, :on_request, fn cx, req ->
          apply(module, :on_request, [cx, req])
        end)

      false ->
        hooks
    end
  end

  defp get_context(:ok), do: %{cx: %{}}

  defp get_context({:ok, cx}), do: %{cx: cx}

  defp get_context({:error, reason}) do
    Output.error(reason)
    abort()
  end

  defp get_context(cx) do
    Output.error("unrecognizable return from init: #{inspect(cx)}")

    IO.puts("""

    Acceptable results are any of
      - :ok
      - {:ok, map()}
      - {:error, binary()}
    """)

    abort()
  end

  defp abort() do
    System.halt(1)
    Process.sleep(:infinity)
  end

  defp children("test", _config) do
    [
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end

  defp children(_type, config) do
    [
      {Blast.Manager, config},
      Blast.Bucket,
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end
end
