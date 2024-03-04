defmodule Blast.Application do
  use Application
  alias Blast.CLI.{Parser, Output}
  alias Blast.Worker.Config
  alias Blast.Hooks
  require Logger

  @env Mix.env()

  @impl true
  def start(_type, _args) do
    LoggerBackends.remove(:console)

    opts = [strategy: :one_for_one, name: Blast.Supervisor]

    children(@env)
    |> Supervisor.start_link(opts)
  end

  defp children(:test) do
    [
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end

  defp children(:dev) do
    [
      Blast.Bucket,
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end

  defp children(:prod) do
    config =
      get_args()
      |> Parser.parse_args()
      |> handle()

    [
      {Blast.Manager, config},
      Blast.Bucket,
      Blast.TUI,
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end

  defp get_args() do
    case {System.argv(), Burrito.Util.Args.get_arguments()} do
      {[], [_, "run" | _]} -> []
      {[], args} -> args
      {args, _} -> args
    end
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
    requests = Blast.Spec.get_requests(args.spec)
    hooks = load_hooks(args.hook_file)

    %Config{
      workers: args.workers,
      frequency: args.frequency,
      requests: requests,
      hooks: hooks
    }
  end

  defp load_hooks(nil), do: %Hooks{}

  defp load_hooks(filepath) do
    case Hooks.load_hooks(filepath) do
      {:ok, hooks} -> hooks
      {:error, reason} ->
        Output.error(reason)
        abort()
    end
  end

  @spec abort() :: no_return()
  defp abort() do
    System.halt(1)
  end
end
