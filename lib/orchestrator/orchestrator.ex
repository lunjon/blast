defmodule Blast.Orchestrator do
  @moduledoc """
  This server holds all current state of the application:
  running/stopped, responses, etc.
  """

  use GenServer
  require Logger
  alias Blast.ConfigStore
  alias Blast.State

  @me __MODULE__

  # There `should` be a Blast.Controller running with a registered pid.
  # Use that to signal a start by sending a message to the server.
  @controller Controller

  # External API
  # ============

  def start_link(config) do
    GenServer.start_link(@me, config, name: @me)
  end

  @impl GenServer
  def init(_config) do
    {:ok, %State{}}
  end

  @doc """
  Starts the blasting.
  Before starting the workers it validates that the endpoints are reachable.
  """
  @spec start() :: :ok | {:error, any()}
  def start() do
    config = ConfigStore.get()
    probe = Application.get_env(:blast, :probe, Blast.TcpProbe)

    with :ok <- probe.probe(config.base_url),
         :ok = GenServer.call(@controller, :start) do
      GenServer.call(@me, {:set_status, :running})

      :ok
    else
      err -> err
    end
  end

  @doc """
  Stop all blasting.
  """
  @spec stop() :: :ok
  def stop() do
    :ok = GenServer.call(@controller, :stop)
    GenServer.call(@me, {:set_status, :idle})

    :ok
  end

  @spec get_status() :: State.status()
  def get_status() do
    %{status: status} = get_state()
    status
  end

  @spec get_state() :: State.t()
  def get_state() do
    GenServer.call(@me, :state)
  end

  @spec put_response(non_neg_integer(), HTTPoison.Response.t()) :: :ok
  def put_response(response, duration) do
    GenServer.cast(@me, {:put_response, response, duration})
  end

  # Internal API
  # ============

  @impl GenServer
  def handle_cast({:put_response, response, duration}, state) do
    state = State.add_response(state, response, duration)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call({:set_status, status}, _from, state) do
    state = State.set_status(state, status)
    {:reply, :ok, state}
  end
end
