defmodule Blast.Results do
  use GenServer
  require Logger

  @me __MODULE__

  def start_link(_) do
    GenServer.start_link(@me, nil, name: @me)
  end

  def init(nil) do
    {:ok, %{}}
  end

  # External API

  def put(url, status) do
    GenServer.cast(@me, {:put, url, status})
  end

  def get() do
    GenServer.call(@me, :get)
  end

  # Internal API

  def handle_cast({:put, url, _status}, state) do
    state = Map.update(state, url, 0, fn count -> count + 1 end)
    {:noreply, state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
