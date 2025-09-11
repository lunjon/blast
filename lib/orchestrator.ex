defmodule Blast.Orchestrator do
  @moduledoc """
  This server holds all current state of the application:
  running/stopped, responses, etc.
  """

  use GenServer
  require Logger
  alias Blast.Stats

  @me __MODULE__

  # There `should` be a Blast.Controller running with a registered pid.
  # Use that to signal a start by sending a message to the server.
  @controller Controller

  @type status() :: :idle | :running

  @type state() :: %{
          state: status(),
          stats: Stats.t()
        }

  # External API
  # ============

  def start_link(config) do
    GenServer.start_link(@me, config, name: @me)
  end

  @impl GenServer
  def init(config) do
    state = %{
      base_url: config.base_url,
      state: :idle,
      stats: %Stats{}
    }

    {:ok, state}
  end

  @doc """
  Starts the blasting.
  Before starting the workers it validates that the endpoints are reachable.
  """
  @spec start() :: :ok | {:error, any()}
  def start() do
    state = get_state()
    probe = Application.get_env(:blast, :probe, Blast.TcpProbe)

    with :ok <- probe.probe(state.base_url),
         :ok = GenServer.call(@controller, :start) do
      GenServer.call(@me, {:set_status, :running})

      :ok
    else
      err -> err
    end
  end

  def stop() do
    :ok = GenServer.call(@controller, :stop)
    GenServer.call(@me, {:set_status, :idle})

    :ok
  end

  @spec get_status() :: status()
  def get_status() do
    %{status: status} = get_state()
    status
  end

  @spec get_stats() :: Stats.t()
  def get_stats() do
    %{stats: stats} = get_state()
    stats
  end

  defp get_state() do
    GenServer.call(@me, :state)
  end

  @spec put_response(non_neg_integer(), HTTPoison.Response.t()) :: :ok
  def put_response(response, duration) do
    GenServer.cast(@me, {:put_response, response, duration})
  end

  # Internal API
  # ============

  @impl GenServer
  def handle_cast({:put_response, response, duration}, %{stats: stats} = state) do
    stats = Stats.add_response(stats, response, duration)
    {:noreply, Map.put(state, :stats, stats)}
  end

  @impl GenServer
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call({:set_status, status}, _from, state) do
    {:reply, :ok, Map.put(state, :status, status)}
  end
end
