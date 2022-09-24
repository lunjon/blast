defmodule Core.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("MANAGEMENT_PORT", "4444"))

    children = [
      Core.Manager,
      Core.Results,
      Core.WorkerSupervisor,
      {Core.Management.API, port},
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
