defmodule Blast.Worker do
  use GenServer, restart: :transient
  alias Blast.Results
  require Logger

  @spec start_link(tuple()) :: {:ok, pid} | {:error, binary()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init({request, _config} = args) do
    Logger.info("Starting worker with request: #{inspect(request)}")
    Process.send_after(self(), :run, 0)
    {:ok, args}
  end

  def handle_info(:run, {req, _config} = state) do
    millis = get_millis()

    HTTPoison.request(req)
    |> add_result(state, millis)
  end

  def add_result({:ok, response}, {_request, config} = state, start) do
    Results.put(response)

    after_millis = wait(get_millis() - start, config.frequency)
    Process.send_after(self(), :run, after_millis)
    {:noreply, state}
  end

  # No frequency limit, just go
  defp wait(_, 0), do: 0

  defp wait(duration, frequency) do
    t = 1.0 / frequency * 1000

    # Wait if current request rate is higher than the frequency
    if duration < t do
      Logger.info("Waating (#{t}): #{t - duration} millis")
      trunc(t - duration)
    else
      0
    end
  end

  defp get_millis(), do: :os.system_time(:millisecond)
end
