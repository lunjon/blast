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
    ]
  end

  defp children(_env) do
    [
      Blast.Collector,
      Blast.WorkerSupervisor,
      Blast.TUI,
    ]
  end
end
