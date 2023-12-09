defmodule Blast.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Blast.Supervisor]

    System.get_env("MIX_ENV", nil)
    |> children()
    |> Supervisor.start_link(opts)
  end

  defp children("test") do
    [
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end

  defp children(_) do
    [
      Blast.Manager,
      Blast.Bucket,
      Blast.WorkerSupervisor,
      {Task.Supervisor, name: Blast.TaskSupervisor}
    ]
  end
end
