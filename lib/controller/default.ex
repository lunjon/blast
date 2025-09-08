defmodule Blast.Controller.Default do
  use Blast.Controller
  require Logger

  @impl Blast.Controller
  def initialize(config) do
    Logger.debug("Blast.Controller.Default - initialized")
    {:ok, config}
  end

  @impl Blast.Controller
  def start(config) do
    Logger.debug("Blast.Controller.Default - started")
    WorkerSupervisor.add_workers(config.workers, config)
    {:ok, config}
  end

  @impl Blast.Controller
  def handle_message(_msg, state), do: state
end
