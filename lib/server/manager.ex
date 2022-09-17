defmodule Blast.Manager do
  require Logger
  use GenServer

  @doc """
  Manager is responsible for managing workers.
  """

  @me Manager

  # API

  def done() do
    GenServer.cast(@me, :done)
  end

  @doc """
  Instructs to stop all workers.
  """
  def stop_all() do
    {:ok, _} = GenServer.call(@me, :shutdown)
  end

  # Server

  # args :: {req, workers, caller}
  def start_link({request, workers, caller}) do
    params = %{
      request: request,
      workers: workers,
      caller: caller,
      nodes: []
    }

    GenServer.start_link(__MODULE__, params, name: @me)
  end

  def init(params) do
    Process.send_after(self(), {:kickoff, params.request}, 0)

    # Start this as a manager node, allowing other nodes connecting
    # as workers in a distributed cluster: Node.connect(:manager@localhost)
    Node.start(:manager@localhost)

    # Enabling monitoring of nodes.
    # This means that a message will be received when a new node connects.
    # See handle_info({:nodeup, addr}, ...)
    :net_kernel.monitor_nodes(true)

    state = Map.put(params, :nodes, [Node.self()])
    {:ok, state}
  end

  def handle_call(:shutdown, state) do
    {:reply, true, state}
  end

  def handle_info({:kickoff, request}, {workers, _, _} = state) do
    Blast.WorkerSupervisor.add_workers(request, workers)

    {:noreply, state}
  end

  # Invoked if another node connects as a worker
  def handle_info({:nodeup, addr}, state) do
    Logger.info("Node connected: #{addr}")
    pid = Node.spawn(addr, Blast.WorkerSupervisor, :add_workers, [state.request, state.workers])
    Logger.info("Spawned more workers on node #{addr} (pid=#{inspect(pid)})")
    state = Map.put(state, :nodes, [addr, state.nodes])
    {:noreply, state}
  end
end
