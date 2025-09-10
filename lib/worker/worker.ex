defmodule Blast.Worker do
  @moduledoc false

  use GenServer, restart: :transient
  alias Blast.{Collector, Config, Hooks, Request}
  alias Blast.AppState
  alias Blast.Worker.WorkerState
  alias Blast.Results.Error
  require Logger

  @spec start_link(Config.t()) :: {:ok, pid()} | {:error, dynamic()}
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def init(config) do
    state = WorkerState.init(config)
    Process.send_after(self(), :run, 0)

    {:ok, state}
  end

  def handle_info(:run, state) do
    requester = Application.get_env(:blast, :requester, Blast.HttpRequester)

    starttime = get_millis()
    {state, req} = WorkerState.get_request(state)

    requester.send(req)
    |> handle_response(state, starttime)

    {:noreply, state}
  end

  def handle_response({:ok, response}, state, starttime) do
    request_duration = get_millis() - starttime
    put_result(request_duration, response)

    wait_time = get_wait_time(request_duration, state.frequency)
    Process.send_after(self(), :run, wait_time)
  end

  def handle_response({:error, error}, _state, _starttime) do
    Logger.error("Error sending request: #{inspect(error)}")
    Error.handle_error(error)
  end

  defp put_result(duration, response), do: AppState.put_response(response, duration)

  defp get_wait_time(_duration, 0), do: 0

  defp get_wait_time(duration, frequency) do
    t = 1.0 / frequency * 1000

    # Wait if current request rate is higher than the frequency
    if duration < t do
      trunc(t - duration)
    else
      0
    end
  end

  defp get_millis(), do: System.monotonic_time(:millisecond)

  defmodule WorkerState do
    alias Blast.{Hooks, Request, Config}

    @moduledoc """
    This is used to track the current state of the worker
    and it provides convenient functions for updating
    and getting the state.

    It also handles the callbacks/hooks and updates the state accordingly.
    """

    @type t :: %__MODULE__{
            hooks: Hooks.t(),
            requests: [Request.t()],
            frequency: integer()
          }

    defstruct frequency: 0,
              requests: [],
              hooks: %Hooks{}

    @spec init(Config.t()) :: t()
    def init(%Config{} = config) do
      hooks = Hooks.start(config.hooks)

      %WorkerState{
        frequency: config.settings.frequency,
        requests: Config.normalized_requests(config),
        hooks: hooks
      }
    end

    @doc """
    Gets a random request and calls the pre_request hook.
    """
    @spec get_request(t()) :: {t(), Request.t()}
    def get_request(%WorkerState{hooks: hooks, requests: reqs} = state) do
      req = Enum.random(reqs)

      {hooks, req} = Hooks.pre_request(hooks, req)
      {update_hooks(state, hooks), req}
    end

    defp update_hooks(state, hooks) do
      put_in(state, [Access.key!(:hooks)], hooks)
    end
  end
end
