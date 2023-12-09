defmodule Blast.WorkerSupervisor do
  use DynamicSupervisor
  require Logger

  @me WorkerSupervisor

  @moduledoc """
  Used for processes that are started on the fly.
  """

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: @me)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_workers(config) do
    for _ <- 1..config.workers do
      res = DynamicSupervisor.start_child(@me, {Blast.Worker, config})

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
