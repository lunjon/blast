defmodule Blast.Application do
  use Application
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
    config = Blast.CLI.parse_args(System.argv())

    [
      {Blast.Manager, config},
      Blast.Bucket,
      Blast.TUI,
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end

  defp children(_type) do
    [
      Blast.Manager,
      Blast.Bucket,
      Blast.TUI,
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end
end
