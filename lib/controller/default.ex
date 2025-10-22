defmodule Blast.Controller.Default do
  @moduledoc false

  use Blast.Controller
  require Logger

  @impl Blast.Controller
  def initialize(_config) do
    Logger.debug("Blast.Controller.Default - initialized")
    {:ok, %{}}
  end

  @impl Blast.Controller
  def start(state, config) do
    Logger.debug("Blast.Controller.Default - started")
    WorkerSupervisor.add_workers(config.workers, config)
    {:ok, state}
  end

  @impl Blast.Controller
  def handle_message(_msg, state), do: state
end
