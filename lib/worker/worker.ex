defmodule Blast.Worker do
  use GenServer, restart: :transient
  alias Blast.{Collector, Config, Hooks, Request}
  alias Blast.Worker.State
  alias Blast.Results.Error
  require Logger

  @spec start_link(Config.t()) :: {:ok, pid()} | {:error, String.t()}
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def init(config) do
    state =
      State.from_config(config)
      |> State.on_start()

    Process.send_after(self(), :run, 0)
    {:ok, state}
  end

  def handle_info(:run, state) do
    requester = Application.get_env(:blast, :requester, Blast.HttpRequester)

    starttime = get_millis()
    {state, req} = State.get_request(state)

    requester.send(req)
    |> handle_response(state, starttime)

    {:noreply, state}
  end

  def handle_response({:ok, response}, state, starttime) do
    request_duration = get_millis() - starttime
    put_result(request_duration, response, state.bucket)

    wait_time = get_wait_time(request_duration, state.frequency)
    Process.send_after(self(), :run, wait_time)
  end

  def handle_response({:error, error}, _state, _starttime) do
    Logger.error("Error sending request: #{inspect(error)}")
    Error.handle_error(error)
  end

  defp put_result(duration, response, nil), do: Collector.put(duration, response)
  defp put_result(duration, response, pid), do: Collector.put(duration, response, pid)

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

  defmodule State do
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
            frequency: integer(),
            bucket: pid()
          }

    defstruct frequency: 0,
              requests: [],
              bucket: nil,
              hooks: %Hooks{}

    @spec from_config(Config.t()) :: State.t()
    def from_config(%Config{frequency: f, requests: reqs, bucket: b, hooks: hs}) do
      %State{
        frequency: case f do
          nil -> 2
          n -> n
        end,
        requests: reqs,
        bucket: b,
        hooks: hs
      }
    end

    @spec on_start(t()) :: t()
    def on_start(state) do
      hooks = Hooks.on_start(state.hooks)
      update(state, :hooks, hooks)
    end

    @doc """
    Gets a random request and calls the on_request hook.
    """
    @spec get_request(t()) :: {t(), Request.t()}
    def get_request(%State{hooks: hooks, requests: reqs} = state) do
      req = Enum.random(reqs)

      {hooks, req} = Hooks.on_request(hooks, req)
      {update(state, :hooks, hooks), req}
    end

    @spec update(any(), atom(), t()) :: t()
    defp update(state, field, value) do
      put_in(state, [Access.key!(field)], value)
    end
  end
end
