defmodule MockRequester do
  @behaviour Blast.Requester
  alias Blast.Request
  alias HTTPoison.Response

  @impl Blast.Requester
  def send(%Request{} = req) do
    request = %HTTPoison.Request{
      method: req.method,
      url: req.url,
      headers: req.headers,
      body: req.body
    }
    res = %Response{
      status_code: 200,
      request_url: "",
      request: request
    }

    {:ok, res}
  end
end

# Register the mock as requester implementation
Application.put_env(:blast, :requester, MockRequester)

require Logger
Logger.configure(level: :none)

ExUnit.start()
