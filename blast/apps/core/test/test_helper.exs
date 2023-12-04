# Setup mock
defmodule CoreTest.RequesterMock do
  @behaviour Core.Requester

  @impl Core.Requester
  def send(_req) do
    {:ok, %HTTPoison.Response{status_code: 200, request_url: "todo"}}
  end
end

Application.put_env(:blast, :requester, BlastTest.RequesterMock)

# Disable logger
require Logger
Logger.configure(level: :none)

ExUnit.start()
