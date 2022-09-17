defmodule Blast.Worker do
  use GenServer, restart: :transient
  alias Blast.Results
  require Logger

  def start_link(request) do
    GenServer.start_link(__MODULE__, request)
  end

  def init(req) do
    Process.send_after(self(), :run, 0)
    {:ok, req}
  end

  def handle_info(:run, req) do
    HTTPoison.request(req)
    |> add_result(req)
  end

  def add_result({:ok, response}, req) do
    Results.put(response)
    send(self(), :run)

    {:noreply, req}
  end
end
