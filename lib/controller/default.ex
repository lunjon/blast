defmodule Blast.Controller.Default do
  use Blast.Controller

  @impl Blast.Controller
  def start({workers, config}) do
    WorkerSupervisor.add_workers(workers, config)
    {:ok, %{config: config}}
  end

  @impl Blast.Controller
  def stop(state), do: state

  @impl true
  def handle_message(_msg, state), do: state
end
