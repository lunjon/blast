defmodule Core.WorkerSupervisor do
  use DynamicSupervisor
  require Logger

  @me WorkerSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: @me)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_workers(worker_config, n) when is_integer(n) and n > 0 do
    for _ <- 1..n do
      res = DynamicSupervisor.start_child(@me, {Core.Worker, worker_config})

      case res do
        {:ok, pid} ->
          Logger.info("Started new worker: #{inspect(pid)}")

        {:error, error} ->
          Logger.error("Error starting worker: #{error}")
      end
    end
  end

  def stop_workers() do
    DynamicSupervisor.which_children(@me)
    |> Enum.each(fn {:undefined, pid, _, _} ->
      DynamicSupervisor.terminate_child(@me, pid)
    end)
  end
end
