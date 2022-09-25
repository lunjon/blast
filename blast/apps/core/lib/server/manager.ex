defmodule Core.Manager do
  require Logger
  use GenServer
  alias Core.{WorkerSupervisor, Worker.Config}

  @me Manager

  @moduledoc """
  Manager is the module for responsible for managing, monitoring
  and distributing of the components of blast.
  """

  @type status() :: :idle | :running
  @type state() :: {list(), status(), Config.t() | nil}

  ##############
  # Public API #
  ##############

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_, name \\ @me) do
    GenServer.start_link(__MODULE__, nil, name: name)
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
  Starts this manager instance as a manager in distributed mode.
  """
  def start_manager(pid \\ @me) do
    GenServer.call(pid, :start_manager)
  end

  @doc """
  Starts this manager instance as a worker in distributed mode.
  Connects to the manager node at the given address.
  """
  @spec start_worker(String.t()) :: :ok
  def start_worker(manager_addr, pid \\ @me) do
    GenServer.call(pid, {:start_worker, manager_addr})
  end

  @doc """
  Instructs manager to stop all workers.
  """
  def stop_all(pid \\ @me) do
    GenServer.call(pid, :shutdown)
  end

  def init(nil) do
    {:ok, {[], :idle, nil}}
  end

  #############################
  # Callbacks for handle_call #
  #############################

  def handle_call(:status, _caller, {_, status, _} = state) do
    {:reply, status, state}
  end

  def handle_call(:start_manager, _caller, state) do
    # Enabling monitoring of nodes.
    # This means that a message will be received when a new node connects.
    # See handle_info({:nodeup, addr}, ...)
    :net_kernel.monitor_nodes(true)
    Node.set_cookie(:secure)
    Node.start(:blast_manager)
    {:reply, :ok, state}
  end

  def handle_call({:start_worker, manager_addr}, _caller, state) do
    manager_node = "blast_manager@#{manager_addr}" |> String.to_atom()
    random_worker_name() |> Node.start()
    Node.set_cookie(:secure)
    res = Node.connect(manager_node)
    Logger.info("Connect: #{inspect(res)}")
    {:reply, :ok, state}
  end

  def handle_call(:shutdown, _caller, {_, :idle, _} = state) do
    {:reply, true, state}
  end

  def handle_call(:shutdown, _caller, {nodes, :running, config}) do
    Enum.each(nodes, fn node ->
      Node.spawn(node, Core.WorkerSupervisor, :stop_workers, [])
    end)

    WorkerSupervisor.stop_workers()
    {:reply, true, {nodes, :idle, config}}
  end

  #############################
  # Callbacks for handle_cast #
  #############################

  def handle_cast({:kickoff, _}, {_, :running, _} = state) do
    Logger.info("Kickoff received, but already running")
    {:noreply, state}
  end

  def handle_cast({:kickoff, config}, {nodes, _, _}) do
    Logger.info("Kickoff received - adding #{config.workers} workers")

    # Add workers for connected nodes
    Enum.each(nodes, fn node ->
      Node.spawn(node, Core.DynamicSupervisor, :add_workers, [config])
    end)

    WorkerSupervisor.add_workers(config)
    {:noreply, {nodes, :running, config}}
  end

  #############################
  # Callbacks for handle_info #
  #############################

  def handle_info({:nodeup, addr}, {nodes, status, config}) do
    nodes =
      if to_string(addr) =~ ~r/manager/ do
        nodes
      else
        Logger.info("Node connected: #{inspect(addr)}")
        [addr | nodes]
      end

    if status == :running do
      Enum.each(nodes, fn node ->
        Node.spawn(node, Core.Manager, :kickoff, [config])
      end)
    end

    {:noreply, {nodes, status}}
  end

  def handle_info({:nodedown, addr}, {nodes, status}) do
    Logger.info("Node disconnected: #{inspect(addr)}")
    nodes = Enum.filter(nodes, fn n -> n != addr end)
    Logger.info("#{Enum.count(nodes)} nodes remaining")
    {:noreply, {nodes, status}}
  end

  defp random_worker_name() do
    s = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
    String.to_atom("worker_" <> s)
  end
end
