defmodule Blast.Gatherer do
  require Logger
  use GenServer

  @me Gatherer

  # API

  def done() do
    GenServer.cast(@me, :done)
  end

  # Server

  # args :: {req, workers, caller}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @me)
  end

  def init({request, workers, caller}) do
    Process.send_after(self(), {:kickoff, request}, 0)
    {:ok, {workers, caller}}
  end

  def handle_cast(:done, {1, caller}) do
    send(caller, :done)
  end

  def handle_cast(:done, {workers, caller}) do
    {:noreply, {workers - 1, caller}}
  end

  def handle_info({:kickoff, request}, {workers, _} = state) do
    1..workers
    |> Enum.each(fn _ -> Blast.WorkerSupervisor.add_worker(request) end)

    {:noreply, state}
  end
end
