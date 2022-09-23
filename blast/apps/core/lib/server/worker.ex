defmodule Core.Worker do
  use GenServer, restart: :transient
  alias Core.Results
  require Logger

  @spec start_link(tuple()) :: {:ok, pid} | {:error, binary()}
  def start_link({request, config}) do
    GenServer.start_link(__MODULE__, {request, config})
  end

  def init(args) do
    Process.send_after(self(), :run, 0)
    {:ok, args}
  end

  def handle_info(:run, {req, _config} = state) do
    millis = get_millis()

    requester = Application.get_env(:blast, :requester, Core.RequesterImpl)

    requester.send(req)
    |> add_result(state, millis)
  end

  def add_result({:ok, response}, {_request, config} = state, start) do
    Results.put(response)

    after_millis = wait(get_millis() - start, config.frequency)
    Process.send_after(self(), :run, after_millis)
    {:noreply, state}
  end

  def add_result({:error, error}, state, _) do
    Logger.error("Error sending request: #{inspect(error)}")
    {:noreply, state}
  end

  # No frequency limit, just go
  defp wait(_, 0), do: 0

  defp wait(duration, frequency) do
    t = 1.0 / frequency * 1000

    # Wait if current request rate is higher than the frequency
    if duration < t do
      trunc(t - duration)
    else
      0
    end
  end

  defp get_millis(), do: System.monotonic_time(:millisecond)
end
