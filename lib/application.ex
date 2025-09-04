defmodule Blast.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    LoggerBackends.remove(:console)

    opts = [strategy: :one_for_one, name: Blast.Supervisor]

    children()
    |> Supervisor.start_link(opts)
  end

  defp children() do
    [
      Blast.Collector,
      Blast.WorkerSupervisor,
      Blast.TUI
    ]
  end
end
