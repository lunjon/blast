defmodule Blast.Worker do
  @moduledoc false

  use GenServer, restart: :transient
  alias Blast.{Config, Hooks, Request}
  alias Blast.Orchestrator
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
    start_time = get_millis()
    {state, req} = get_request(state)

    case Blast.HttpClient.send(req) do
      {:ok, response} -> handle_response(state, response, start_time)
      {:error, error} -> handle_error(error, req)
    end

    {:noreply, state}
  end

  defp handle_response(state, response, start_time) do
    duration = get_millis() - start_time
    Orchestrator.put_response(response, duration)

    wait_time = get_wait_time(duration, state.frequency)
    Process.send_after(self(), :run, wait_time)
  end

  def handle_error(error, request) do
    Logger.error("Error sending request: #{inspect(error)}")

    case error do
      %HTTPoison.Error{reason: :timeout} ->
        Logger.warning("Timeout error - waiting 5 s before retrying")

        Orchestrator.put_error(request, "timeout")
        Process.send_after(self(), :run, 5000)

      %HTTPoison.Error{reason: :econnrefused} ->
        IO.puts(:stderr, "unreachable endpoint configured: exiting")
        System.halt(1)

      %HTTPoison.Error{reason: :closed} ->
        IO.puts(:stderr, "target endpoint closed: exiting")
        System.halt(1)

      _ ->
        IO.puts(:stderr, "unexpected error: #{inspect(error)}")
        System.halt(1)
    end
  end

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
