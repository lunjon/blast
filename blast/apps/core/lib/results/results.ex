defmodule Blast.Results do
  use GenServer
  require Logger
  alias Blast.Result

  @me __MODULE__

  def start_link(_) do
    GenServer.start_link(@me, nil, name: @me)
  end

  def init(nil) do
    {:ok, %Result{}}
  end

  # External API

  @spec put(HTTPoison.Response.t()) :: :ok
  def put(response) do
    GenServer.cast(@me, {:put, response})
  end

  def get() do
    GenServer.call(@me, :get)
  end

  # Internal API

  def handle_cast({:put, response}, state) do
    {:noreply, Result.update(state, response)}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
