defmodule Blast.Controller.Rampup do
  use Blast.Controller

  @type props :: %{
          add: integer(),
          every: integer(),
          start: integer(),
          target: integer()
        }

  @impl Blast.Controller
  def stop(state) do
    {:ok, Map.put(state, :running, false)}
  end

  @impl Blast.Controller
  def initialize(%Config{settings: settings} = config) do
    state = %{running: false, config: config, props: settings.control.props, workers: 0}
    {:ok, state}
  end

  @impl Blast.Controller
  def start(%{props: props, config: config} = state) do
    send_self(:tick, props.every * 1000)
    :ok = WorkerSupervisor.add_workers(props.start, config)

    state
    |> Map.put(:running, true)
    |> Map.put(:workers, props.start)

    Logger.info("Starting Rampup controller with properties: #{inspect(props)}")

    {:ok, state}
  end

  @impl Blast.Controller
  def handle_message(:tick, %{running: false} = state) do
    state
  end

  @impl Blast.Controller
  def handle_message(:tick, %{config: config, props: props} = state) do
    {workers, to_add} =
      if state.workers + props.add < props.target do
        {state.workers + props.add, props.add}
      else
        to_add = props.target - state.workers
        {props.target, to_add}
      end

    if to_add > 0 do
      WorkerSupervisor.add_workers(props.add, config)
    end

    if workers < props.target do
      # Wait for `every` to process again
      send_self(:tick, props.every * 1000)
    else
      Logger.info("Controller.Rampup reached target number of workers: #{workers}")
    end

    Map.put(state, :workers, workers)
  end
end
