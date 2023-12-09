# Setup mock
defmodule BlastTest.RequesterMock do
  @behaviour Blast.Requester

  @impl Blast.Requester
  def send(_req) do
    {:ok, %HTTPoison.Response{status_code: 200, request_url: "todo"}}
  end
end

Application.put_env(:blast, :requester, BlastTest.RequesterMock)

# Disable logger
require Logger
Logger.configure(level: :none)

ExUnit.start()
