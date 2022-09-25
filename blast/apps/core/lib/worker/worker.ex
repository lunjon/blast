defmodule Core.Worker do
  use GenServer, restart: :transient
  alias Core.Results
  require Logger

  @spec start_link(Core.Worker.Config.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def init(config) do
    Process.send_after(self(), :run, 0)
    {:ok, config}
  end

  def handle_info(:run, state) do
    millis = get_millis()

    requester = Application.get_env(:blast, :requester, Core.RequesterImpl)

    requester.send(state.request)
    |> handle_response(state, millis)
  end

  def handle_response({:ok, response}, config, start) do
    put_result(response, config.results_bucket)

    after_millis = wait(get_millis() - start, config.frequency)
    Process.send_after(self(), :run, after_millis)
    {:noreply, config}
  end

  def handle_response({:error, error}, config, _) do
    Logger.error("Error sending request: #{inspect(error)}")
    {:noreply, config}
  end

  defp put_result(response, pid) do
    case pid do
      nil ->
        Results.put(response)

      p ->
        Results.put(response, p)
    end
  end

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
