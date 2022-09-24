defmodule Core.Manager do
  require Logger
  use GenServer
  alias Core.WorkerSupervisor

  @me Manager

  @moduledoc """
  Manager is the module for responsible for managing, monitoring
  and distributing of the components of blast.
  """

  ##############
  # Public API #
  ##############

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @me)
  end

  @doc """
  Starts `workers` by using the `worker_config`.
  """
  @spec kickoff(Core.Worker.Config.t(), integer()) :: :ok
  def kickoff(worker_config, workers) do
    state = %{
      worker_config: worker_config,
      workers: workers
    }

    GenServer.cast(@me, {:kickoff, state})
  end

  @doc """
  Starts this manager instance as a manager in distributed mode.
  """
  def start_manager() do
    GenServer.call(@me, :start_manager)
  end

  @doc """
  Starts this manager instance as a worker in distributed mode.
  Connects to the manager node at the given address.
  """
  @spec start_worker(String.t()) :: :ok
  def start_worker(manager_addr) do
    GenServer.call(@me, {:start_worker, manager_addr})
  end

  @doc """
  Instructs manager to stop all workers.
  """
  def stop_all() do
    GenServer.call(@me, :shutdown)
  end

  def init(nil) do
    {:ok, {[], nil}}
  end

  #############################
  # Callbacks for handle_call #
  #############################

  def handle_call(:start_manager, _caller, state) do
    # Enabling monitoring of nodes.
    # This means that a message will be received when a new node connects.
    # See handle_info({:nodeup, addr}, ...)
    :net_kernel.monitor_nodes(true)
    Node.start(:blast_manager)
    Node.set_cookie(:secure)
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

  def handle_call(:shutdown, _caller, nil) do
    {:reply, true, nil}
  end

  def handle_call(:shutdown, _caller, {nodes, _}) do
    Enum.each(nodes, fn node ->
      Node.spawn(node, Core.WorkerSupervisor, :stop_workers, [])
    end)

    WorkerSupervisor.stop_workers()
    {:reply, true, {nodes, nil}}
  end

  #############################
  # Callbacks for handle_cast #
  #############################

  def handle_cast({:kickoff, state}, {nodes, _}) do
    Logger.info("Kickoff received - adding #{state.workers} workers")
    Logger.info("Request: #{inspect(state.worker_config.request)}")

    # Add workers for connected nodes
    Enum.each(nodes, fn node ->
      Node.spawn(node, Core.DynamicSupervisor, :add_workers, [state.worker_config, state.workers])
    end)

    WorkerSupervisor.add_workers(state.worker_config, state.workers)
    {:noreply, {nodes, state}}
  end

  #############################
  # Callbacks for handle_info #
  #############################

  def handle_info({:nodeup, addr}, {nodes, conf}) do
    nodes =
      if to_string(addr) =~ ~r/manager/ do
        nodes
      else
        Logger.info("Node connected: #{inspect(addr)}")
        [addr | nodes]
      end

    Enum.each(nodes, fn node ->
      Node.spawn(node, Core.Manager, :kickoff, [conf.worker_config, conf.workers])
    end)

    {:noreply, {nodes, conf}}
  end

  def handle_info({:nodedown, addr}, {nodes, conf}) do
    Logger.info("Node disconnected: #{inspect(addr)}")
    nodes = Enum.filter(nodes, fn n -> n != addr end)
    Logger.info("#{Enum.count(nodes)} nodes remaining")
    {:noreply, {nodes, conf}}
  end

  defp random_worker_name() do
    s = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
    String.to_atom("worker_" <> s)
  end
end
