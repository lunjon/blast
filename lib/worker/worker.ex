defmodule Blast.Worker do
  @moduledoc false

  use GenServer, restart: :transient
  alias Blast.{Config, Hooks, Request}
  alias Blast.Orchestrator
  alias Blast.Results.Error
  require Logger

  @spec start_link(Config.t()) :: {:ok, pid()} | {:error, dynamic()}
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  @type state() :: %{
          frequency: integer(),
          requests: [Request.t()],
          hooks: Hooks.t()
        }

  def init(config) do
    # See typespec above for state.
    state = %{
      frequency: config.frequency,
      requests: Config.normalized_requests(config),
      hooks: Hooks.start(config.hooks)
    }

    Process.send_after(self(), :run, 0)
    {:ok, state}
  end

  def handle_info(:run, state) do
    starttime = get_millis()
    {state, req} = get_request(state)

    requester = Application.get_env(:blast, :requester, Blast.HttpRequester)

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

  defp put_result(duration, response), do: Orchestrator.put_response(response, duration)

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

  @spec get_request(state()) :: {state(), Request.t()}
  defp get_request(%{hooks: hooks, requests: reqs} = state) do
    req = Enum.random(reqs)

    {hooks, req} = Hooks.pre_request(hooks, req)
    {Map.put(state, :hooks, hooks), req}
  end
end
