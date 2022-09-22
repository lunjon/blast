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
    GenServer.call(@me, :shutdown)
  end

  # Server

  # args :: {worker_config, workers, caller}
  def start_link({worker_config, workers, caller}) do
    state = %{
      worker_config: worker_config,
      workers: workers,
      caller: caller,
      nodes: []
    }

    GenServer.start_link(__MODULE__, state, name: @me)
  end

  def init(state) do
    # Enabling monitoring of nodes.
    # This means that a message will be received when a new node connects.
    # See handle_info({:nodeup, addr}, ...)
    :net_kernel.monitor_nodes(true)

    Process.send_after(self(), :kickoff, 0)

    {:ok, Map.put(state, :nodes, [Node.self()])}
  end

  def handle_call(:shutdown, _caller, state) do
    # TODO: call for each node
    Blast.WorkerSupervisor.stop_workers()
    {:reply, true, state}
  end

  def handle_info(:kickoff, state) do
    Blast.WorkerSupervisor.add_workers(state.worker_config, state.workers)

    {:noreply, state}
  end
end
