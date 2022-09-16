defmodule Blast.Gatherer do
  require Logger
  use GenServer
  alias Blast.Results

  @me Gatherer

  # API

  def result(url, status) do
    GenServer.cast(@me, {:result, url, status})
  end

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

  def handle_cast({:result, url, status}, state) do
    Results.put(url, status)
    {:noreply, state}
  end

  def handle_info({:kickoff, request}, {workers, _} = state) do
    1..workers
    |> Enum.each(fn _ -> Blast.WorkerSupervisor.add_worker(request) end)

    {:noreply, state}
  end
end
