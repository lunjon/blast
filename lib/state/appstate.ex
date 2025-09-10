defmodule Blast.AppState do
  @moduledoc """
  This server holds all current state of the application:
  running/stopped, responses, etc.
  """

  use GenServer
  require Logger
  alias Blast.Stats

  @me __MODULE__

  # External API
  # ============

  def start_link() do
    GenServer.start_link(@me, [], name: @me)
  end

  @impl true
  def init(_) do
    # The server keeps the following state:
    state = %{
      # idle | running
      state: :idle,
      stats: %Stats{}
    }

    {:ok, state}
  end

  @spec put_response(non_neg_integer(), HTTPoison.Response.t()) :: :ok
  def put_response(response, duration) do
    GenServer.cast(@me, {:put_response, response, duration})
  end

  # # @spec get(pid()) :: Result.t()
  # def get_base_url() do
  #   GenServer.call(pid, :get)
  # end

  # Internal API
  # ============

  @impl true
  def handle_cast({:put_response, response, duration}, state) do
    {:noreply, Stats.add_response(state, response, duration)}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
