defmodule Core.Bucket do
  use GenServer
  require Logger
  alias Core.Result

  @moduledoc """
  Responsible for collecting results during a particular run.
  """

  @me __MODULE__

  def start_link(:test) do
    GenServer.start_link(@me, nil)
  end

  def start_link(_) do
    GenServer.start_link(@me, nil, name: @me)
  end

  def init(nil) do
    {:ok, %Result{}}
  end

  # External API

  @spec put(HTTPoison.Response.t()) :: :ok
  def put(response, pid \\ @me) do
    GenServer.cast(pid, {:put, response})
  end

  @spec get() :: Result.t()
  def get(pid \\ @me) do
    GenServer.call(pid, :get)
  end

  # Internal API

  def handle_cast({:put, response}, state) do
    {:noreply, Result.add_response(state, response)}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
