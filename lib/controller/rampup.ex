defmodule Blast.Controller.Rampup do
  use Blast.Controller

  @type props :: %{
          add: integer(),
          every: integer(),
          start: integer(),
          target: integer()
        }

  @impl Blast.Controller
  def stop(state), do: state

  @impl Blast.Controller
  def start({config, props}) do
    send_self(:tick, props.every * 1000)

    starting_workers = props.start

    :ok = WorkerSupervisor.add_workers(starting_workers, config)
    state = %{config: config, props: props, workers: starting_workers}

    Logger.info("Starting Rampup controller with properties: #{inspect(props)}")

    {:ok, state}
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
