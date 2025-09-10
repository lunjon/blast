defmodule Blast.AppState do
  @moduledoc """
  This server holds all current state of the application:
  running/stopped, responses, etc.
  """

  use GenServer
  require Logger
  alias Blast.Result

  @me __MODULE__

  # External API
  # ============

  def start_link(name \\ @me) do
    GenServer.start_link(@me, nil, name: name)
  end

  def init(nil) do
    {:ok, %Result{}}
  end

  @spec put(integer(), HTTPoison.Response.t()) :: :ok
  def put(duration, response, pid \\ @me) do
    GenServer.cast(pid, {:put, duration, response})
  end

  @spec get(pid()) :: Result.t()
  def get(pid \\ @me) do
    GenServer.call(pid, :get)
  end

  # Internal API
  # ============

  def handle_cast({:put, duration, response}, result) do
    {:noreply, Result.add_response(result, duration, response)}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
