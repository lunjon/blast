defmodule Blast.WorkerSupervisor do
  @moduledoc false

  use DynamicSupervisor
  require Logger

  @me WorkerSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: @me)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Adds as a worker that uses the `config`.
  """
  @spec add_worker(Blast.Config.t()) :: :ok
  def add_worker(config) do
    res = DynamicSupervisor.start_child(@me, {Blast.Worker, config})

    case res do
      {:ok, pid} ->
        Logger.info("Started new worker: #{inspect(pid)}")

      {:error, error} ->
        Logger.error("Error starting worker: #{error}")
    end

    :ok
  end

  @doc """
  Adds as many workers as specified in the `config`.
  """
  @spec add_workers(integer(), Blast.Config.t()) :: :ok
  def add_workers(count, config) do
    for _ <- 1..count do
      add_worker(config)
    end

    :ok
  end

  def stop_workers() do
    DynamicSupervisor.which_children(@me)
    |> Enum.each(fn {:undefined, pid, _, _} ->
      DynamicSupervisor.terminate_child(@me, pid)
    end)
  end
end
