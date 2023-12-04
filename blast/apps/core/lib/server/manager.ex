defmodule Core.Manager do
  require Logger
  use GenServer
  alias Core.{WorkerSupervisor, Worker.Config}

  @me Manager

  @moduledoc """
  Manager is the module for responsible for managing
  the state of the runtime.
  """

  @type status() :: :idle | :running
  @type state() :: {list(), status(), Config.t() | nil}

  ##############
  # Public API #
  ##############

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(:test) do
    GenServer.start_link(__MODULE__, nil)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @me)
  end

  @doc """
  Gets current status.
  """
  @spec get_status(pid() | nil) :: status()
  def get_status(pid \\ @me) do
    GenServer.call(pid, :status)
  end

  @doc """
  Start blasting using `config`.
  """
  @spec kickoff(Config.t()) :: :ok
  def kickoff(config, pid \\ @me) do
    GenServer.cast(pid, {:kickoff, config})
  end

  @doc """
  Instructs manager to stop all workers.
  """
  def stop_all(pid \\ @me) do
    GenServer.call(pid, :shutdown)
  end

  def init(nil) do
    {:ok, {:idle, nil}}
  end

  #############################
  # Callbacks for handle_call #
  #############################

  def handle_call(:status, _caller, {status, _} = state) do
    {:reply, status, state}
  end

  def handle_call(:shutdown, _caller, {:idle, _} = state) do
    {:reply, true, state}
  end

  def handle_call(:shutdown, _caller, {:running, config}) do
    WorkerSupervisor.stop_workers()
    {:reply, true, {:idle, config}}
  end

  #############################
  # Callbacks for handle_cast #
  #############################

  def handle_cast({:kickoff, _}, {:running, _} = state) do
    Logger.info("Kickoff received, but already running")
    {:noreply, state}
  end

  def handle_cast({:kickoff, config}, {_, _}) do
    Logger.info("Kickoff received - adding #{config.workers} workers")
    WorkerSupervisor.add_workers(config)
    {:noreply, {:running, config}}
  end
end
