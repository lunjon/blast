defmodule Blast.Worker do
  use GenServer, restart: :transient
  alias Blast.Results
  require Logger

  def start_link(url) do
    GenServer.start_link(__MODULE__, url)
  end

  def init(url) do
    Process.send_after(self(), :run, 0)
    {:ok, url}
  end

  def handle_info(:run, url) do
    HTTPoison.get(url)
    |> add_result(url)
  end

  def add_result({:ok, response}, url) do
    Results.put(response.request_url, response.status_code)
    send(self(), :run)

    {:noreply, url}
  end
end
