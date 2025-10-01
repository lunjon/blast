defmodule Blast.Application do
  use Application

  @moduledoc false

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Blast.Supervisor]

    children()
    |> Supervisor.start_link(opts)
  end

  defp children() do
    [
      Blast.WorkerSupervisor,
      {Plug.Cowboy, scheme: :http, plug: Blast.WebApp, port: 4000}
    ]
  end
end
