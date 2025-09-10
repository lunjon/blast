defmodule Blast.Controller.Default do
  use Blast.Controller

  @impl Blast.Controller
  def initialize({workers, config}) do
    {:ok, %{config: config, workers: workers}}
  end

  @impl Blast.Controller
  def start(%{config: config, workers: workers}) do
    WorkerSupervisor.add_workers(workers, config)
    {:ok, %{config: config}}
  end

  @impl Blast.Controller
  def stop(state), do: state

  @impl Blast.Controller
  def handle_message(_msg, state), do: state
end
