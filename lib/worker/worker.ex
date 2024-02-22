defmodule Blast.Worker do
  use GenServer, restart: :transient
  alias Blast.Bucket
  alias Blast.Worker.Config
  alias Blast.Results.Error
  require Logger

  @spec start_link(Config.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def init(config) do
    Process.send_after(self(), :run, 0)
    {:ok, config}
  end

  def handle_info(:run, config) do
    requester = Application.get_env(:blast, :requester, Blast.RequesterImpl)
    millis = get_millis()
    {config, req} = get_request(config)

    config =
      Map.update!(config, :requests, fn [req | rest] ->
        rest ++ [req]
      end)

    requester.send(req)
    |> handle_response(config, millis)
  end

  def handle_response({:ok, response}, config, start) do
    put_result(response, config.bucket)

    after_millis = get_wait_time(get_millis() - start, config.frequency)
    Process.send_after(self(), :run, after_millis)

    {:noreply, config}
  end

  def handle_response({:error, error}, config, _) do
    Logger.error("Error sending request: #{inspect(error)}")

    Error.handle_error(error)

    {:noreply, config}
  end

  defp get_request(%Config{requests: requests, hooks: hooks} = cfg) do
    req = Enum.random(requests)

    case hooks[:on_request] do
      nil ->
        {cfg, req}

      hook ->
        {cx, req} = hook.(hooks.cx, req)
        cfg = update_in(cfg.hooks.cx, fn _ -> cx end)
        {cfg, req}
    end
  end

  defp put_result(response, nil), do: Bucket.put(response)
  defp put_result(response, pid), do: Bucket.put(response, pid)

  defp get_wait_time(_, 0), do: 0

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
end
