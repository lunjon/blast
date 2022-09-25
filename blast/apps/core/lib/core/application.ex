defmodule Core.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Core.Supervisor]

    Mix.env()
    |> children()
    |> Supervisor.start_link(opts)
  end

  defp children(:test) do
    [
      Core.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end

  defp children(_) do
    port = String.to_integer(System.get_env("MANAGEMENT_PORT", "4444"))

    [
      Core.Manager,
      Core.Results,
      Core.WorkerSupervisor,
      {Core.Management.API, port},
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end
end
