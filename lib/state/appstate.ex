defmodule Blast.AppState do
  @moduledoc """
  This server holds all current state of the application:
  running/stopped, responses, etc.
  """

  use GenServer
  require Logger
  alias Blast.Spec
  alias Blast.Stats

  @me __MODULE__

  # See Blast.Controller
  @controller Controller

  @type state() :: %{
          state: :idle | :running,
          base_url: String.t(),
          stats: Stats.t()
        }

  # External API
  # ============

  def start_link(spec) do
    GenServer.start_link(@me, spec, name: @me)
  end

  @impl GenServer
  def init(%Spec{base_url: base_url}) do
    # See typedef for state above.
    state = %{
      state: :idle,
      base_url: base_url,
      stats: %Stats{}
    }

    {:ok, state}
  end

  def start() do
    # There `should` be a Blast.Controller running with a registered pid.
    # Use that to signal a start by sending a message to the server.
    GenServer.call(@controller, :start)
  end

  def stop() do
    # There `should` be a Blast.Controller running with a registered pid.
    # Use that to signal a start by sending a message to the server.
    GenServer.call(@controller, :stop)
  end

  def get_stats() do
    %{stats: stats} = GenServer.call(@me, :state)
    stats
  end

  @spec put_response(non_neg_integer(), HTTPoison.Response.t()) :: :ok
  def put_response(response, duration) do
    GenServer.cast(@me, {:put_response, response, duration})
  end

  # Internal API
  # ============

  @impl GenServer
  def handle_cast({:put_response, response, duration}, state) do
    {:noreply, Stats.add_response(state, response, duration)}
  end

  @impl GenServer
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end
end
