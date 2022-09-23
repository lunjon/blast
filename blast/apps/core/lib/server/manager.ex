defmodule Core.Manager do
  require Logger
  use GenServer

  @me Manager

  @doc """
  Manager is the module for responsible for managing, monitoring
  and distributing of the components of blast.
  """

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @me)
  end

  @doc """
  Starts `workers` by using the `worker_config`.
  """
  @spec kickoff(Core.WorkerConfig.t(), integer()) :: :ok
  def kickoff(worker_config, workers) do
    state = %{
      worker_config: worker_config,
      workers: workers
    }

    GenServer.cast(@me, {:kickoff, state})
  end

  def start_manager() do
    GenServer.call(@me, :start_manager)
  end

  def start_worker(manager_node) do
    GenServer.call(@me, {:start_worker, manager_node})
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

  def handle_call(:start_manager, _caller, state) do
    # Enabling monitoring of nodes.
    # This means that a message will be received when a new node connects.
    # See handle_info({:nodeup, addr}, ...)
    :net_kernel.monitor_nodes(true)
    Node.start(:blast_manager)
    Node.set_cookie(:secure)
    {:reply, :ok, state}
  end

  def handle_call({:start_worker, manager_node}, _caller, state) do
    Node.start(:blast_worker)
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

    Core.WorkerSupervisor.stop_workers()
    {:reply, true, {nodes, nil}}
  end

  def handle_cast({:kickoff, state}, {nodes, _}) do
    Logger.info("Kickoff received - adding #{state.workers} workers")
    Logger.info("Request: #{inspect(state.worker_config.request)}")

    # Add workers for connected nodes
    Enum.each(nodes, fn node ->
      Node.spawn(node, Core.WorkerSupervisor, :add_workers, [state.worker_config, state.workers])
    end)

    Core.WorkerSupervisor.add_workers(state.worker_config, state.workers)
    {:noreply, {nodes, state}}
  end

  # Info callbacks for manager

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
end
