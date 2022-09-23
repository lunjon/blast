defmodule Core.Worker do
  use GenServer, restart: :transient
  alias Core.Results
  require Logger

  @spec start_link(Core.WorkerConfig.t()) :: {:ok, pid} | {:error, String.t()}
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
    |> add_result(state, millis)
  end

  def add_result({:ok, response}, config, start) do
    Results.put(response)

    after_millis = wait(get_millis() - start, config.frequency)
    Process.send_after(self(), :run, after_millis)
    {:noreply, config}
  end

  def add_result({:error, error}, config, _) do
    Logger.error("Error sending request: #{inspect(error)}")
    {:noreply, config}
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
