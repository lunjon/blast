defmodule Blast.WorkerSupervisor do
  use DynamicSupervisor

  @me WorkerSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: @me)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_worker(request) do
    {:ok, _pid} = DynamicSupervisor.start_child(@me, {Blast.Worker, request})
  end

  def add_workers(_request, 0), do: :ok

  def add_workers(request, n) when is_integer(n) and n > 0 do
    {:ok, _pid} = DynamicSupervisor.start_child(@me, {Blast.Worker, request})
    add_workers(request, n - 1)
  end

  def stop_workers() do
    DynamicSupervisor.which_children(@me)
    |> Enum.each(fn {:undefined, pid, _, _} ->
      DynamicSupervisor.terminate_child(@me, pid)
    end)
  end
end
