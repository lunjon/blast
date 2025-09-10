defmodule Blast.Application do
  use Application
  require Logger

  @moduledoc false

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Blast.Supervisor]

    children()
    |> Supervisor.start_link(opts)
  end

  defp children() do
    [
      Blast.ConfigStore,
      Blast.WorkerSupervisor,
      {Plug.Cowboy, scheme: :http, plug: Blast.WebApp, port: 4040}
    ]
  end
end
