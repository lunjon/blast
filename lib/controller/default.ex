defmodule Blast.Controller.Default do
  use Blast.Controller
  require Logger

  @impl Blast.Controller
  def initialize({workers, config}) do
    Logger.debug("Blast.Controller.Default - initialized")
    {:ok, %{config: config, workers: workers}}
  end

  @impl Blast.Controller
  def start(%{config: config, workers: workers}) do
    Logger.debug("Blast.Controller.Default - started")
    WorkerSupervisor.add_workers(workers, config)
    {:ok, %{config: config}}
  end

  @impl Blast.Controller
  def stop(state), do: state

  @impl Blast.Controller
  def handle_message(_msg, state), do: state
end
