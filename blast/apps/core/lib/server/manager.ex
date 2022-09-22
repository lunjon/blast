defmodule Core.Manager do
  require Logger
  use GenServer

  @doc """
  Manager is responsible for managing workers.
  """

  @me Manager

  # API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @me)
  end

  def kickoff(worker_config, workers) do
    state = %{
      worker_config: worker_config,
      workers: workers,
      nodes: []
    }

    GenServer.cast(@me, {:kickoff, state})
  end

  @doc """
  Instructs to stop all workers.
  """
  def stop_all() do
    GenServer.call(@me, :shutdown)
  end

  # Server

  def init(nil) do
    # Enabling monitoring of nodes.
    # This means that a message will be received when a new node connects.
    # See handle_info({:nodeup, addr}, ...)
    :net_kernel.monitor_nodes(true)

    {:ok, nil}
  end

  def handle_call(:shutdown, nil) do
    {:reply, true, nil}
  end

  def handle_call(:shutdown, _) do
    # TODO: call for each node
    Core.WorkerSupervisor.stop_workers()
    {:reply, true, nil}
  end

  def handle_cast({:kickoff, state}, _) do
    Logger.info("Kickoff received - adding workers")
    Core.WorkerSupervisor.add_workers(state.worker_config, state.workers)
    {:noreply, state}
  end
end
