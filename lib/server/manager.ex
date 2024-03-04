defmodule Blast.Manager do
  require Logger
  use GenServer
  alias Blast.{WorkerSupervisor, Worker.Config}

  @me Manager

  @moduledoc """
  Manager is the module for responsible for managing
  the state of the runtime.
  """

  @type status() :: :idle | :running
  @type state() :: {status(), Config.t() | nil}

  ##############
  # Public API #
  ##############

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(:test) do
    GenServer.start_link(__MODULE__, nil)
  end

  def start_link([]) do
    # This gets called from the application when running CLI.main.
    GenServer.start_link(__MODULE__, nil, name: @me)
  end

  def start_link(config) do
    # Starts running right away.
    GenServer.start_link(__MODULE__, config, name: @me)
  end

  @doc """
  Gets current status.
  """
  @spec get_status(pid() | nil) :: status()
  def get_status(pid \\ @me) do
    GenServer.call(pid, :status)
  end

  @doc """
  Gets current configuration.
  """
  @spec get_config(pid() | nil) :: nil | Config.t()
  def get_config(pid \\ @me) do
    GenServer.call(pid, :get_config)
  end

  @doc """
  Set configuration to the given value.
  """
  @spec set_config(Config.t(), pid()) :: :ok
  def set_config(config, pid \\ @me) do
    GenServer.call(pid, {:set_config, config})
  end

  @doc """
  Start blasting using initial configuration.
  """
  @spec kickoff() :: :ok | {:error, String.t()}
  def kickoff() do
    config = GenServer.call(@me, :get_config)

    case config do
      nil -> {:error, "no configuration set"}
      _ -> kickoff(config)
    end
  end

  @doc """
  Start blasting using a new `config`.
  """
  @spec kickoff(Config.t()) :: :ok
  def kickoff(config, pid \\ @me) do
    GenServer.cast(pid, {:kickoff, config})
  end

  @doc """
  Instructs manager to stop all workers.
  """
  def stop_all(pid \\ @me) do
    GenServer.call(pid, :stop)
  end

  def init(nil) do
    {:ok, {:idle, nil}}
  end

  def init(config) do
    Process.send_after(self(), :start, 10)
    {:ok, {:running, config}}
  end

  #############################
  # Callbacks for handle_call #
  #############################

  def handle_call({:set_config, config}, _caller, {status, _}) do
    if status == :running do
      WorkerSupervisor.stop_workers()
      WorkerSupervisor.add_workers(config)
    end

    {:reply, :ok, {status, config}}
  end

  def handle_call(:get_config, _caller, {_, config} = state) do
    {:reply, config, state}
  end

  def handle_call(:status, _caller, {status, _} = state) do
    {:reply, status, state}
  end

  def handle_call(:stop, _caller, {:idle, _} = state) do
    {:reply, true, state}
  end

  def handle_call(:stop, _caller, {:running, config}) do
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
    start_workers(config)
  end

  def handle_info(:start, {_, config}) do
  	start_workers(config)
  end

  defp start_workers(config) do
    WorkerSupervisor.add_workers(config)
    {:noreply, {:running, config}}
  end
end
